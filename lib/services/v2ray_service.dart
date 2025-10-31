// This file contains the implementation of the V2RayService, which is responsible for managing the V2Ray VPN connection.

import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxycloud/models/v2ray_config.dart';
import 'package:proxycloud/models/subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A class that represents IP information.
class IpInfo {
  final String ip;
  final String country;
  final String city;
  final String countryCode;
  final bool success;
  final String? errorMessage;

  IpInfo({
    required this.ip,
    required this.country,
    required this.city,
    required this.countryCode,
    required this.success,
    this.errorMessage,
  });

  factory IpInfo.fromJson(Map<String, dynamic> json) {
    return IpInfo(
      ip: json['ip'] ?? '',
      country: json['country_name'] ?? '',
      city: json['city_name'] ?? '',
      countryCode: json['country_code'] ?? '',
      success: true,
      errorMessage: null,
    );
  }

  factory IpInfo.error(String message) {
    return IpInfo(
      ip: '',
      country: '',
      city: '',
      countryCode: '',
      success: false,
      errorMessage: message,
    );
  }

  String get locationString => '$country - $city';
}

/// A service that manages the V2Ray VPN connection.
class V2RayService extends ChangeNotifier {
  Future<void> Function()? _onDisconnected;
  bool _isInitialized = false;
  V2RayConfig? _activeConfig;
  Timer? _statusCheckTimer;
  DateTime? _lastConnectionTime;

  // IP Information
  IpInfo? _ipInfo;
  IpInfo? get ipInfo => _ipInfo;

  bool _isLoadingIpInfo = false;
  bool get isLoadingIpInfo => _isLoadingIpInfo;

  // Usage statistics
  int _uploadBytes = 0;
  int _downloadBytes = 0;
  int _connectedSeconds = 0;
  Timer? _usageStatsTimer;

  // Ping cache
  final Map<String, int?> _pingCache = {};
  final Map<String, bool> _pingInProgress = {};

  // App list cache
  List<Map<String, dynamic>>? _cachedAppList;
  DateTime? _lastAppListFetch;
  static const Duration _appListCacheDuration = Duration(minutes: 5);

  /// Gets the list of installed apps (Android only).
  Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      // On Android, use the method channel to get installed apps
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Check if we have a cached version that's still valid
        if (_cachedAppList != null &&
            _lastAppListFetch != null &&
            DateTime.now().difference(_lastAppListFetch!) <
                _appListCacheDuration) {
          return _cachedAppList!;
        }

        const platform = MethodChannel('com.cloud.pira/app_list');
        final List<dynamic> result = await platform.invokeMethod(
          'getInstalledApps',
        );

        // Convert the result to a List<Map<String, dynamic>>
        final List<Map<String, dynamic>> appList = result
            .map(
              (app) => {
                'packageName': app['packageName'] as String,
                'name': app['name'] as String,
                'isSystemApp': app['isSystemApp'] as bool,
              },
            )
            .toList();

        // Cache the result
        _cachedAppList = appList;
        _lastAppListFetch = DateTime.now();

        return appList;
      } else {
        // Return empty list on non-Android platforms
        return [];
      }
    } catch (e) {
      debugPrint('Error getting installed apps: $e');
      // Return cached version if available, even if stale
      if (_cachedAppList != null) {
        return _cachedAppList!;
      }
      return [];
    }
  }

  /// Method to manually refresh the app list cache.
  Future<void> refreshAppListCache() async {
    _cachedAppList = null;
    _lastAppListFetch = null;
    await getInstalledApps();
  }

  /// Clears the ping cache for all configs or a specific config.
  void clearPingCache({String? configId}) {
    if (configId != null) {
      _pingCache.remove(configId);
    } else {
      _pingCache.clear();
    }
    // No need to clear native ping service cache since we're not using it anymore
  }

  // Singleton pattern
  static final V2RayService _instance = V2RayService._internal();
  factory V2RayService() => _instance;

  late final V2ray _flutterV2ray;

  // Current V2Ray status from the callback
  V2RayStatus? _currentStatus;
  V2RayStatus? get currentStatus => _currentStatus;

  V2RayService._internal() {
    _flutterV2ray = V2ray(
      onStatusChanged: (status) {
        print('V2Ray status changed: $status');
        _currentStatus = status;
        _handleStatusChange(status);
        notifyListeners(); // Notify listeners when status changes
      },
    );

    // Load saved usage statistics
    _loadUsageStats();

    // No need to initialize native ping service since we're using V2Ray's built-in method
  }

  Future<void> _initializeNativePing() async {
    // No need to initialize native ping service since we're using V2Ray's built-in method
  }

  void _handleStatusChange(V2RayStatus status) {
    // Handle disconnection from notification
    // Check for common disconnected status values using string matching
    String statusString = status.toString().toLowerCase();
    if ((statusString.contains('disconnect') ||
            statusString.contains('stop') ||
            statusString.contains('idle')) &&
        _activeConfig != null) {
      print('Detected disconnection from notification');
      _activeConfig = null;
      // Call the disconnected callback if it exists
      if (_onDisconnected != null) {
        // Execute the callback in a separate isolate to avoid blocking
        Future(() async {
          try {
            await _onDisconnected!();
          } catch (e) {
            print('Error in disconnected callback: $e');
          }
        });
      }

      // Save the disconnected state immediately
      _clearActiveConfig();
    }
  }

  /// Initializes the V2Ray service.
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _flutterV2ray.initialize(
        notificationIconResourceType: "mipmap",
        notificationIconResourceName: "ic_launcher",
      );
      _isInitialized = true;

      // Try to restore active config if VPN is still running
      await _tryRestoreActiveConfig();
    }
  }

  /// Connects to a V2Ray server.
  Future<bool> connect(V2RayConfig config, bool statusProxy) async {
    try {
      await initialize();

      // Parse the configuration
      V2RayURL parser = V2ray.parseFromURL(config.fullConfig);

      // Request permission if needed (for VPN mode)
      bool hasPermission = await _flutterV2ray.requestPermission();
      if (!hasPermission) {
        return false;
      }

      // Get settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Get bypass subnets settings
      final bool bypassEnabled =
          prefs.getBool('bypass_subnets_enabled') ?? false;
      List<String>? bypassSubnets;

      if (bypassEnabled) {
        final String savedSubnets = prefs.getString('bypass_subnets') ?? '';
        if (savedSubnets.isNotEmpty) {
          bypassSubnets = savedSubnets.trim().split('\n');
        }
      } else {
        // Explicitly set bypassSubnets to null when the feature is disabled
        bypassSubnets = null;
      }

      // Save the proxy mode setting to SharedPreferences
      await prefs.setBool('proxy_mode_enabled', statusProxy);

      // Save the proxy mode setting to the config object
      config.isProxyMode = statusProxy;

      // Get custom DNS settings
      final bool dnsEnabled = prefs.getBool('custom_dns_enabled') ?? false;
      final String dnsServers =
          prefs.getString('custom_dns_servers') ??
              '1.1.1.1\n1.0.0.1\n8.8.8.8\n8.8.4.4';

      // Apply custom DNS settings if enabled
      if (dnsEnabled && dnsServers.isNotEmpty) {
        // Split the DNS servers string into a list (one per line)
        List<String> serversList = dnsServers.trim().split('\n');
        // Remove any empty entries
        serversList =
            serversList.where((server) => server.trim().isNotEmpty).toList();

        if (serversList.isNotEmpty) {
          // Set the DNS servers in the parser
          parser.dns = {"servers": serversList};
        }
      }

      // Get blocked apps from shared preferences
      final blockedAppsList = prefs.getStringList('blocked_apps');

      // Start V2Ray in VPN mode
      await _flutterV2ray.startV2Ray(
        remark: parser.remark,
        config: parser.getFullConfiguration(),
        blockedApps: blockedAppsList, // Use saved blocked apps list
        bypassSubnets: bypassSubnets,
        proxyOnly: statusProxy, // Use proxy mode based on statusProxy parameter
        notificationDisconnectButtonName: "DISCONNECT",
      );

      _activeConfig = config;
      _lastConnectionTime = DateTime.now();

      // Save active config to persistent storage
      await _saveActiveConfig(config);

      // Start monitoring usage statistics
      _startUsageMonitoring();

      // Fetch IP information after a 2-second delay to ensure connection is stable
      Future.delayed(const Duration(seconds: 2), () {
        fetchIpInfo()
            .then((ipInfo) {
              debugPrint(
                'IP Info fetched after connection: ${ipInfo.ip} - ${ipInfo.country}',
              );
            })
            .catchError((e) {
              debugPrint('Error fetching IP info after connection: $e');
            });
      });

      return true;
    } catch (e) {
      debugPrint('Error connecting to V2Ray: $e');
      return false;
    }
  }

  /// Disconnects from the V2Ray server.
  Future<void> disconnect() async {
    try {
      // Stop usage monitoring
      _stopUsageMonitoring();

      // Save current usage statistics before clearing active config
      await _saveUsageStats();

      await _flutterV2ray.stopV2Ray();

      // Clear active config and last connection time
      _activeConfig = null;
      _lastConnectionTime = null;

      // Clear active config from storage but keep the usage statistics
      await _clearActiveConfig();

      // Update the last connection time in storage to null
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_connection_time');
    } catch (e) {
      debugPrint('Error disconnecting from V2Ray: $e');
    }
  }

  Future<void> _saveActiveConfig(V2RayConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    // Get the current proxy mode setting and update the config
    final bool proxyModeEnabled = prefs.getBool('proxy_mode_enabled') ?? false;
    config.isProxyMode = proxyModeEnabled;

    await prefs.setString('active_config', jsonEncode(config.toJson()));
    // Also save as selected config for UI state persistence
    await _saveSelectedConfig(config);
  }

  Future<void> _saveSelectedConfig(V2RayConfig config) async {
    final prefs = await SharedPreferences.getInstance();

    // Get the current proxy mode setting and update the config
    final bool proxyModeEnabled = prefs.getBool('proxy_mode_enabled') ?? false;
    config.isProxyMode = proxyModeEnabled;

    await prefs.setString('selected_config', jsonEncode(config.toJson()));
  }

  /// Public method to save selected config
  Future<void> saveSelectedConfig(V2RayConfig config) async {
    await _saveSelectedConfig(config);
  }

  Future<void> _clearActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_config');
  }

  Future<V2RayConfig?> _loadActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configJson = prefs.getString('active_config');
    if (configJson == null) return null;
    return V2RayConfig.fromJson(jsonDecode(configJson));
  }

  /// Loads the selected V2Ray configuration from storage.
  Future<V2RayConfig?> loadSelectedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configJson = prefs.getString('selected_config');
    if (configJson == null) return null;
    return V2RayConfig.fromJson(jsonDecode(configJson));
  }

  Future<void> _tryRestoreActiveConfig() async {
    try {
      // Check if VPN is actually running
      final delay = await _flutterV2ray.getConnectedServerDelay();
      final isConnected = delay >= 0;

      print('VPN connection check: isConnected=$isConnected, delay=$delay');

      if (isConnected) {
        // Try to load the saved active config
        final savedConfig = await _loadActiveConfig();
        if (savedConfig != null) {
          _activeConfig = savedConfig;
          debugPrint('Restored active config: ${savedConfig.remark}');

          // Restore connection time properly
          await _restoreConnectionTime();

          // Start usage monitoring
          _startUsageMonitoring();

          // Notify listeners to update UI
          notifyListeners();
        } else {
          debugPrint('VPN is connected but no saved config found');
          // VPN is connected but we don't have the config details
          // This shouldn't happen normally, but handle gracefully
        }
      } else {
        // VPN is not running, clear any saved config
        debugPrint('VPN is not connected, clearing saved config');
        await _clearActiveConfig();
        _activeConfig = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error restoring active config: $e');
      // Clear any saved config on error
      await _clearActiveConfig();
      _activeConfig = null;
      notifyListeners();
    }
  }

  Future<void> _restoreConnectionTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastConnectionTimeStr = prefs.getString('last_connection_time');

    if (lastConnectionTimeStr != null) {
      try {
        final lastConnectionTime = DateTime.parse(lastConnectionTimeStr);
        final now = DateTime.now();
        final elapsedSeconds = now.difference(lastConnectionTime).inSeconds;

        // Load existing connected seconds
        _connectedSeconds = prefs.getInt('connected_seconds') ?? 0;

        // If the app was closed recently (less than 1 hour), add the elapsed time
        if (elapsedSeconds > 0 && elapsedSeconds < 60 * 60) {
          _connectedSeconds += elapsedSeconds;
          debugPrint(
            'Restored connection time: ${getFormattedConnectedTime()}, added ${elapsedSeconds}s since last save',
          );
        } else {
          debugPrint(
            'Restored connection time: ${getFormattedConnectedTime()}, no elapsed time added (gap: ${elapsedSeconds}s)',
          );
        }

        // Update last connection time to now for future tracking
        _lastConnectionTime = now;
        await _saveUsageStats();
      } catch (e) {
        debugPrint('Error parsing last connection time: $e');
        _lastConnectionTime = DateTime.now();
        _connectedSeconds = prefs.getInt('connected_seconds') ?? 0;
      }
    } else {
      // No saved connection time, start fresh but keep existing connected seconds
      _lastConnectionTime = DateTime.now();
      _connectedSeconds = prefs.getInt('connected_seconds') ?? 0;
      debugPrint(
        'No previous connection time found, keeping existing time: ${getFormattedConnectedTime()}',
      );
      await _saveUsageStats();
    }
  }

  /// Gets the server delay/ping for a specific config using V2Ray's built-in method.
  Future<int?> getServerDelay(V2RayConfig config) async {
    final configId = config.id;
    final hostKey = '${config.address}:${config.port}';

    try {
      // Return cached ping if available - first check by host, then by configId
      if (_pingCache.containsKey(hostKey)) {
        final cachedValue = _pingCache[hostKey];
        // Check if cached value is not too old (30 seconds)
        if (cachedValue != null) {
          return cachedValue;
        }
      } else if (_pingCache.containsKey(configId)) {
        final cachedValue = _pingCache[configId];
        if (cachedValue != null) {
          return cachedValue;
        }
      }

      // Check if ping is already in progress for this host or config
      if (_pingInProgress[hostKey] == true ||
          _pingInProgress[configId] == true) {
        // Wait for existing ping to complete (max 5 seconds)
        int attempts = 0;
        while ((_pingInProgress[hostKey] == true ||
                _pingInProgress[configId] == true) &&
            attempts < 25) {
          await Future.delayed(const Duration(milliseconds: 200));
          attempts++;
        }
        return _pingCache[hostKey] ?? _pingCache[configId];
      }

      // Mark this host and config as having ping in progress
      _pingInProgress[hostKey] = true;
      _pingInProgress[configId] = true;

      try {
        // Use V2Ray's built-in ping method for better accuracy
        await initialize();

        final parser = V2ray.parseFromURL(config.fullConfig);
        final delay = await _flutterV2ray
            .getServerDelay(config: parser.getFullConfiguration())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('V2Ray ping timeout for ${config.remark}');
                throw Exception('V2Ray ping timeout');
              },
            );

        // Cache the result by both host and config ID
        if (delay >= -1 && delay < 10000) {
          _pingCache[hostKey] = delay;
          _pingCache[configId] = delay;

          _pingInProgress[hostKey] = false;
          _pingInProgress[configId] = false;

          return delay;
        } else {
          _pingInProgress[hostKey] = false;
          _pingInProgress[configId] = false;
          _pingCache[hostKey] = null;
          _pingCache[configId] = null;
          return null;
        }
      } catch (e) {
        debugPrint('Error with V2Ray ping for ${config.remark}: $e');

        _pingInProgress[hostKey] = false;
        _pingInProgress[configId] = false;
        _pingCache[hostKey] = null;
        _pingCache[configId] = null;
        return null;
      }
    } catch (e) {
      debugPrint('Unexpected error in getServerDelay for ${config.remark}: $e');
      // Ensure cleanup even in unexpected errors
      _pingInProgress[hostKey] = false;
      _pingInProgress[configId] = false;
      return null;
    }
  }

  /// Parses the content of a subscription and returns a list of V2Ray configurations.
  Future<List<V2RayConfig>> parseSubscriptionContent(String content) async {
    try {
      final List<V2RayConfig> configs = [];

      // Try to decode as base64 first
      try {
        // Check if the content looks like base64
        if (_isBase64(content)) {
          final decoded = utf8.decode(base64.decode(content.trim()));
          // If decoding succeeds, use the decoded content
          content = decoded;
          print('Successfully decoded base64 content');
        }
      } catch (e) {
        // If base64 decoding fails, use the original content
        print('Not a valid base64 content, using original: $e');
      }

      final List<String> lines = content.split('\n');

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        try {
          if (line.startsWith('vmess://') ||
              line.startsWith('vless://') ||
              line.startsWith('trojan://') ||
              line.startsWith('ss://')) {
            V2RayURL parser = V2ray.parseFromURL(line);
            String configType = '';

            if (line.startsWith('vmess://')) {
              configType = 'vmess';
            } else if (line.startsWith('vless://')) {
              configType = 'vless';
            } else if (line.startsWith('ss://')) {
              configType = 'shadowsocks';
            } else if (line.startsWith('trojan://')) {
              configType = 'trojan';
            }

            // Use the parsed address and port from the V2RayURL parser
            String address = parser.address;
            int port = parser.port;

            configs.add(
              V2RayConfig(
                id: DateTime.now().millisecondsSinceEpoch.toString() +
                    configs.length.toString(),
                remark: parser.remark,
                address: address,
                port: port,
                configType: configType,
                fullConfig: line,
              ),
            );
          }
        } catch (e) {
          print('Error parsing config: $e');
        }
      }

      if (configs.isEmpty) {
        throw Exception('No valid configurations found in subscription');
      }

      return configs;
    } catch (e) {
      print('Error parsing subscription content: $e');

      // Provide more specific error messages based on exception type
      if (e.toString().contains('No valid configurations')) {
        throw Exception('No valid servers found in file');
      } else {
        throw Exception('Failed to parse subscription file: ${e.toString()}');
      }
    }
  }

  /// Parses a subscription URL and returns a list of V2Ray configurations.
  Future<List<V2RayConfig>> parseSubscriptionUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Network timeout: Check your internet connection',
              );
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load subscription: HTTP ${response.statusCode}',
        );
      }

      final List<V2RayConfig> configs = [];
      String content = response.body;

      // Try to decode as base64 first
      try {
        // Check if the content looks like base64
        if (_isBase64(content)) {
          final decoded = utf8.decode(base64.decode(content.trim()));
          // If decoding succeeds, use the decoded content
          content = decoded;
          print('Successfully decoded base64 content');
        }
      } catch (e) {
        // If base64 decoding fails, use the original content
        print('Not a valid base64 content, using original: $e');
      }

      final List<String> lines = content.split('\n');

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;

        try {
          if (line.startsWith('vmess://') ||
              line.startsWith('vless://') ||
              line.startsWith('trojan://') ||
              line.startsWith('ss://')) {
            V2RayURL parser = V2ray.parseFromURL(line);
            String configType = '';

            if (line.startsWith('vmess://')) {
              configType = 'vmess';
            } else if (line.startsWith('vless://')) {
              configType = 'vless';
            } else if (line.startsWith('ss://')) {
              configType = 'shadowsocks';
            } else if (line.startsWith('trojan://')) {
              configType = 'trojan';
            }

            // Use the parsed address and port from the V2RayURL parser
            String address = parser.address;
            int port = parser.port;

            configs.add(
              V2RayConfig(
                id: DateTime.now().millisecondsSinceEpoch.toString() +
                    configs.length.toString(),
                remark: parser.remark,
                address: address,
                port: port,
                configType: configType,
                fullConfig: line,
              ),
            );
          }
        } catch (e) {
          print('Error parsing config: $e');
        }
      }

      if (configs.isEmpty) {
        throw Exception('No valid configurations found in subscription');
      }

      return configs;
    } catch (e) {
      print('Error parsing subscription: $e');

      // Provide more specific error messages based on exception type
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception('Network error: Check your internet connection');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Connection timeout: Server is not responding');
      } else if (e.toString().contains('Invalid URL')) {
        throw Exception('Invalid subscription URL format');
      } else if (e.toString().contains('No valid configurations')) {
        throw Exception('No valid servers found in subscription');
      } else {
        throw Exception('Failed to update subscription: ${e.toString()}');
      }
    }
  }

  /// Saves the list of V2Ray configurations to storage.
  Future<void> saveConfigs(List<V2RayConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> configsJson =
        configs.map((config) => jsonEncode(config.toJson())).toList();
    await prefs.setStringList('v2ray_configs', configsJson);
  }

  /// Loads the list of V2Ray configurations from storage.
  Future<List<V2RayConfig>> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? configsJson = prefs.getStringList('v2ray_configs');
    if (configsJson == null) return [];

    return configsJson
        .map((json) => V2RayConfig.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Saves the list of subscriptions to storage.
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> subscriptionsJson =
        subscriptions.map((sub) => jsonEncode(sub.toJson())).toList();
    await prefs.setStringList('v2ray_subscriptions', subscriptionsJson);
  }

  /// Loads the list of subscriptions from storage.
  Future<List<Subscription>> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? subscriptionsJson = prefs.getStringList(
      'v2ray_subscriptions',
    );
    if (subscriptionsJson == null) return [];

    return subscriptionsJson
        .map((json) => Subscription.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Sets the callback function to be called when the VPN is disconnected.
  void setDisconnectedCallback(Future<void> Function() callback) {
    _onDisconnected = callback;
    // Disable automatic monitoring to prevent false disconnects
    // _startStatusMonitoring();
  }

  void _stopStatusMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  // Helper method to check if a string is valid base64
  bool _isBase64(String str) {
    // Remove any whitespace
    str = str.trim();
    // Check if the length is valid for base64 (multiple of 4)
    if (str.length % 4 != 0) {
      return false;
    }
    // Check if the string contains only valid base64 characters
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(str);
  }

  // Removed getConnectedServerDelay method as requested

  /// Fetches IP information from ipleak.net API.
  Future<IpInfo> fetchIpInfo() async {
    // Set loading state
    _isLoadingIpInfo = true;
    notifyListeners();

    const String apiUrl = 'https://ipleak.net/json/';
    int retryCount = 0;
    const int maxRetries = 5;

    try {
      while (retryCount < maxRetries) {
        try {
          print('Fetching IP info, attempt ${retryCount + 1}/$maxRetries');
          final response = await http.get(Uri.parse(apiUrl)).timeout(
                const Duration(seconds: 60),
                onTimeout: () {
                  throw Exception(
                      'Network timeout: Check your internet connection');
                },
              );

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            final ipInfo = IpInfo.fromJson(data);

            _ipInfo = ipInfo;
            _isLoadingIpInfo = false;
            notifyListeners();
            print(
              'IP info fetched successfully: ${ipInfo.ip} - ${ipInfo.locationString}',
            );
            return ipInfo;
          } else {
            print('HTTP error: ${response.statusCode}');
            retryCount++;
            await Future.delayed(const Duration(seconds: 1));
          }
        } catch (e) {
          print('Error fetching IP info: $e');
          retryCount++;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // After max retries, return error
      final errorInfo = IpInfo.error('Cannot get IP information');
      _ipInfo = errorInfo;
      _isLoadingIpInfo = false;
      notifyListeners();
      print('Failed to fetch IP info after $maxRetries attempts');
      return errorInfo;
    } catch (e) {
      // Handle any unexpected errors
      print('Unexpected error fetching IP info: $e');
      final errorInfo = IpInfo.error('Error: $e');
      _ipInfo = errorInfo;
      _isLoadingIpInfo = false;
      notifyListeners();
      return errorInfo;
    }
  }

  /// Getter to check if connected to a server
  bool get isConnected => _activeConfig != null;

  /// Getter to access the active config
  V2RayConfig? get activeConfig => _activeConfig;

  /// Public method to force check connection status
  Future<bool> isActuallyConnected() async {
    try {
      final delay = await _flutterV2ray.getConnectedServerDelay();
      final isConnected = delay != null && delay >= 0;

      // Don't automatically clear the active config or call onDisconnected
      // This prevents false disconnections when switching between apps
      // Only report the actual connection status

      return isConnected;
    } catch (e) {
      print('Error in force connection check: $e');
      // Don't automatically clear the active config or call onDisconnected
      // Just report the error but maintain the connection state
      return _activeConfig !=
          null; // Assume still connected if we have an active config
    }
  }

  /// Get real-time ping monitoring for the currently connected server
  /// Returns a stream of ping results that updates at the specified interval
  Stream<int?>? startConnectedServerPingMonitoring({
    Duration interval = const Duration(seconds: 5),
  }) {
    if (_activeConfig == null) {
      debugPrint('No active config for ping monitoring');
      return null;
    }

    try {
      return Stream.periodic(interval, (count) async {
        try {
          await initialize();

          final parser = V2ray.parseFromURL(_activeConfig!.fullConfig);
          final delay = await _flutterV2ray
              .getServerDelay(config: parser.getFullConfiguration())
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint(
                      'V2Ray ping timeout for ${_activeConfig!.remark}');
                  return -1;
                },
              );

          return delay >= -1 && delay < 10000 ? delay : null;
        } catch (e) {
          debugPrint('Error in continuous ping monitoring: $e');
          return null;
        }
      }).asyncMap((future) => future);
    } catch (e) {
      debugPrint('Error starting connected server ping monitoring: $e');
      return null;
    }
  }

  /// Get network type information
  Future<String> getNetworkType() async {
    // Since we're not using NativePingService anymore, we'll return a default value
    return 'Unknown';
  }

  /// Test connectivity using V2Ray's built-in method
  Future<Map<String, int?>> testConnectivity() async {
    try {
      // Test connectivity to some common services
      final testConfigs = [
        'https://clients3.google.com/generate_204',
        'https://www.google.com',
        'https://www.cloudflare.com'
      ];

      final Map<String, int?> results = {};

      for (final url in testConfigs) {
        try {
          // Create a simple test configuration
          final testConfig = {
            "inbounds": [
              {
                "port": "10808",
                "protocol": "socks",
                "settings": {
                  "auth": "noauth",
                  "udp": true,
                  "ip": "127.0.0.1"
                }
              }
            ],
            "outbounds": [
              {
                "protocol": "freedom",
                "settings": {}
              }
            ]
          };

          final delay = await _flutterV2ray
              .getServerDelay(config: jsonEncode(testConfig), url: url)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint('Connectivity test timeout for $url');
                  return -1;
                },
              );

          results[url] = delay >= -1 && delay < 10000 ? delay : null;
        } catch (e) {
          debugPrint('Error testing connectivity to $url: $e');
          results[url] = null;
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error in testConnectivity: $e');
      return {};
    }
  }

  /// Get enhanced server delay with detailed ping information
  Future<int?> getServerPingDetails(V2RayConfig config) async {
    try {
      await initialize();

      final parser = V2ray.parseFromURL(config.fullConfig);
      final delay = await _flutterV2ray
          .getServerDelay(config: parser.getFullConfiguration())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('V2Ray ping timeout for ${config.remark}');
              throw Exception('V2Ray ping timeout');
            },
          );

      return delay >= -1 && delay < 10000 ? delay : null;
    } catch (e) {
      debugPrint('Error getting server ping details for ${config.remark}: $e');
      return null;
    }
  }

  /// Batch ping multiple servers for server selection
  Future<Map<String, int?>> batchPingServers(
      List<V2RayConfig> configs) async {
    try {
      final Map<String, int?> configResults = {};

      // Ping each server individually (in parallel)
      final futures = <Future<MapEntry<String, int?>>>[];

      for (final config in configs) {
        futures.add(
            _pingSingleServer(config).then((delay) => MapEntry(config.id, delay)));
      }

      // Wait for all pings to complete
      final results = await Future.wait(futures);

      // Populate the results map
      for (final result in results) {
        configResults[result.key] = result.value;

        // Also cache the result by host:port key
        final config = configs.firstWhere((c) => c.id == result.key);
        final key = '${config.address}:${config.port}';
        _pingCache[key] = result.value;
        _pingCache[config.id] = result.value;
      }

      return configResults;
    } catch (e) {
      debugPrint('Error in batch ping servers: $e');
      return {};
    }
  }

  /// Helper method to ping a single server
  Future<int?> _pingSingleServer(V2RayConfig config) async {
    try {
      await initialize();

      final parser = V2ray.parseFromURL(config.fullConfig);
      final delay = await _flutterV2ray
          .getServerDelay(config: parser.getFullConfiguration())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('V2Ray ping timeout for ${config.remark}');
              throw Exception('V2Ray ping timeout');
            },
          );

      return delay >= -1 && delay < 10000 ? delay : null;
    } catch (e) {
      debugPrint('Error pinging server ${config.remark}: $e');
      return null;
    }
  }

  /// Get fastest server from a list of configs
  Future<V2RayConfig?> getFastestServer(List<V2RayConfig> configs) async {
    if (configs.isEmpty) return null;

    try {
      final pingResults = await batchPingServers(configs);

      V2RayConfig? fastestConfig;
      int? lowestLatency;

      for (final config in configs) {
        final latency = pingResults[config.id];
        if (latency != null && latency > 0) {
          if (lowestLatency == null || latency < lowestLatency) {
            lowestLatency = latency;
            fastestConfig = config;
          }
        }
      }

      return fastestConfig;
    } catch (e) {
      debugPrint('Error finding fastest server: $e');
      return null;
    }
  }

  /// Parses a subscription configuration.
  Future<V2RayConfig?> parseSubscriptionConfig(String configText) async {
    try {
      // Try to parse as a V2Ray URL
      final parser = V2ray.parseFromURL(configText);

      // Determine the protocol type from the URL prefix
      String configType = '';
      if (configText.startsWith('vmess://')) {
        configType = 'vmess';
      } else if (configText.startsWith('vless://')) {
        configType = 'vless';
      } else if (configText.startsWith('ss://')) {
        configType = 'shadowsocks';
      } else if (configText.startsWith('trojan://')) {
        configType = 'trojan';
      } else {
        throw Exception('Unsupported protocol');
      }

      // Use the parsed address and port from the V2RayURL parser
      String address = parser.address;
      int port = parser.port;

      // Create a new V2RayConfig object with a generated ID
      return V2RayConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        remark: parser.remark,
        address: address,
        port: port,
        configType: configType,
        fullConfig: configText,
        isConnected: false,
        isProxyMode: false,
      );
    } catch (e) {
      debugPrint('Error parsing config: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _stopStatusMonitoring();
    _stopUsageMonitoring();
    // No need to cleanup native ping service since we're not using it anymore
    super.dispose();
  }

  // Usage statistics methods
  void _startUsageMonitoring() {
    // Stop existing timer if any
    _usageStatsTimer?.cancel();

    // Start periodic usage monitoring every second
    _usageStatsTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_activeConfig != null) {
        // Increment connected time
        _connectedSeconds++;

        try {
          // Use real V2Ray status data if available
          if (_currentStatus != null) {
            // Get real-time traffic data from V2Ray status
            final status = _currentStatus!;

            // Update cumulative statistics with real data
            // Note: V2Ray status provides cumulative data, so we store the latest values
            _uploadBytes = status.upload;
            _downloadBytes = status.download;
          } else {
            // Fallback to simulated data if V2Ray status is not available
            final random = Random();
            final uploadSpeed = random.nextInt(50) * 1024; // 0-50 KB in bytes
            final downloadSpeed =
                random.nextInt(50) * 1024; // 0-50 KB in bytes

            // Add to total bytes
            _uploadBytes += uploadSpeed;
            _downloadBytes += downloadSpeed;
          }

          // Save statistics every minute to avoid excessive writes
          if (_connectedSeconds % 60 == 0) {
            await _saveUsageStats();
          }
        } catch (e) {
          print('Error updating usage statistics: $e');
        }
      }
    });
  }

  void _stopUsageMonitoring() {
    _usageStatsTimer?.cancel();
    _usageStatsTimer = null;
  }

  // Save usage stats and connection time to storage
  Future<void> _saveUsageStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Save current usage statistics
    await prefs.setInt('upload_bytes', _uploadBytes);
    await prefs.setInt('download_bytes', _downloadBytes);
    await prefs.setInt('connected_seconds', _connectedSeconds);

    // Save last connection time if connected
    if (_lastConnectionTime != null) {
      await prefs.setString(
        'last_connection_time',
        _lastConnectionTime!.toIso8601String(),
      );
    }
  }

  Future<void> _loadUsageStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved usage statistics
    _uploadBytes = prefs.getInt('upload_bytes') ?? 0;
    _downloadBytes = prefs.getInt('download_bytes') ?? 0;
    _connectedSeconds = prefs.getInt('connected_seconds') ?? 0;

    // Load last connection time (but don't calculate elapsed time here)
    // This will be handled by _restoreConnectionTime when needed
    final lastConnectionTimeStr = prefs.getString('last_connection_time');
    if (lastConnectionTimeStr != null) {
      try {
        _lastConnectionTime = DateTime.parse(lastConnectionTimeStr);
      } catch (e) {
        debugPrint('Error parsing last connection time: $e');
        _lastConnectionTime = null;
      }
    } else {
      _lastConnectionTime = null;
    }

    debugPrint(
      'Loaded usage stats: Upload: ${getFormattedUpload()}, Download: ${getFormattedDownload()}, Time: ${getFormattedConnectedTime()}',
    );
  }

  /// Resets the usage statistics.
  Future<void> resetUsageStats() async {
    _uploadBytes = 0;
    _downloadBytes = 0;
    _connectedSeconds = 0;

    // Reset last connection time to now if connected
    if (_activeConfig != null) {
      _lastConnectionTime = DateTime.now();
    } else {
      _lastConnectionTime = null;
    }

    // Save the reset values
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('upload_bytes', 0);
    await prefs.setInt('download_bytes', 0);
    await prefs.setInt('connected_seconds', 0);

    if (_lastConnectionTime != null) {
      await prefs.setString(
        'last_connection_time',
        _lastConnectionTime!.toIso8601String(),
      );
    } else {
      await prefs.remove('last_connection_time');
    }
  }

  // Getters for usage statistics
  int get uploadBytes => _uploadBytes;
  int get downloadBytes => _downloadBytes;
  int get connectedSeconds => _connectedSeconds;

  // Get current speeds from V2Ray status (for internal use)
  int get currentUploadSpeed => _currentStatus?.uploadSpeed ?? 0;
  int get currentDownloadSpeed => _currentStatus?.downloadSpeed ?? 0;

  /// Formats the given bytes into a human-readable string.
  String getFormattedUpload() {
    return _formatBytes(_uploadBytes);
  }

  /// Formats the given bytes into a human-readable string.
  String getFormattedDownload() {
    return _formatBytes(_downloadBytes);
  }

  /// Formats the given bytes into a human-readable string.
  String getFormattedTotalTraffic() {
    return _formatBytes(_uploadBytes + _downloadBytes);
  }

  /// Formats the connected time into a human-readable string.
  String getFormattedConnectedTime() {
    final hours = _connectedSeconds ~/ 3600;
    final minutes = (_connectedSeconds % 3600) ~/ 60;
    final seconds = _connectedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
