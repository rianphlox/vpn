import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import '../models/vpn_server.dart';
import '../models/vpn_status.dart';
import 'proxy_service.dart';

/// VPN service using OpenVPN Flutter package with local Japan VPN configuration
class VPNService extends ChangeNotifier {
  static final VPNService _instance = VPNService._internal();
  factory VPNService() => _instance;
  VPNService._internal() {
    _initializeOpenVPN();
    _loadLastConnectedServer();
  }

  // OpenVPN Flutter instance
  late OpenVPN _openVPN;

  VPNStatus _status = VPNStatus(state: VPNConnectionState.disconnected);
  final List<VPNServer> _servers = [];
  VPNServer? _currentServer;
  Timer? _connectionTimer;

  // Japan VPN server configuration from assets
  static const String _jpnServerName = 'Japan VPN Server';
  static const String _jpnServerHost = 'public-vpn-48.opengw.net';
  static const String _jpnServerCountry = 'Japan';
  static const String _jpnServerFlag = '🇯🇵';

  // Getters
  VPNStatus get status => _status;
  List<VPNServer> get servers => _servers;
  VPNServer? get currentServer => _currentServer;

  /// Initialize OpenVPN Flutter and load Japan VPN server
  void _initializeOpenVPN() {
    try {
      _openVPN = OpenVPN(
        onVpnStatusChanged: (data) {
          debugPrint('OpenVPN Status: ${data.toString()}');
          _handleVPNStatusChange(data);
        },
        onVpnStageChanged: (data, raw) {
          debugPrint('OpenVPN Stage: $data - Raw: $raw');
          _handleVPNStageChange(data, raw);
        },
      );

      debugPrint('OpenVPN instance created successfully');
    } catch (e) {
      debugPrint('Error initializing OpenVPN: $e');
    }

    // Load the Japan VPN server
    _loadJapanVPNServer();
  }

  /// Load Japan VPN server configuration
  void _loadJapanVPNServer() {
    final japanServer = VPNServer(
      name: _jpnServerName,
      ip: _jpnServerHost,
      country: _jpnServerCountry,
      city: 'Tokyo', // Required field
      flagCode: 'jp', // Required field
      ovpnConfig: '', // Will be loaded from assets
      latency: 50, // Estimated latency
      uptime: 99, // High uptime
      signalStrength: 90, // Strong signal
    );

    _servers.clear();
    _servers.add(japanServer);
    notifyListeners();
    debugPrint('Loaded Japan VPN server');
  }

  /// Handle OpenVPN status changes
  void _handleVPNStatusChange(VpnStatus? status) {
    if (status == null) return;

    // Handle the VPN status based on string representation
    // The openvpn_flutter package uses different status values
    final statusString = status.toString();
    debugPrint('VPN Status String: $statusString');

    if (statusString.contains('connected')) {
      _updateStatus(VPNConnectionState.connected);
      _startConnectionTimer();

      // Enable proxy routing for Japan server when connected
      _enableProxyForJapanServer();
    } else if (statusString.contains('disconnected')) {
      _updateStatus(VPNConnectionState.disconnected);
      _stopConnectionTimer();

      // Disable proxy when disconnected
      ProxyService.disableProxy();
    } else if (statusString.contains('error')) {
      _updateStatus(VPNConnectionState.error, 'VPN connection error');
    } else {
      debugPrint('Unknown VPN status: $status');
    }
  }

  /// Handle OpenVPN stage changes
  void _handleVPNStageChange(VPNStage stage, String raw) {
    switch (stage) {
      case VPNStage.connecting:
        _updateStatus(VPNConnectionState.connecting);
        break;
      case VPNStage.authenticating:
        _updateStatus(VPNConnectionState.authenticating);
        break;
      case VPNStage.connected:
        _updateStatus(VPNConnectionState.connected);
        _startConnectionTimer();
        break;
      case VPNStage.disconnected:
        _updateStatus(VPNConnectionState.disconnected);
        _stopConnectionTimer();
        break;
      case VPNStage.error:
        _updateStatus(VPNConnectionState.error, raw);
        break;
      default:
        debugPrint('Unknown VPN stage: $stage');
    }
  }

  /// Connect to Japan VPN server using local OVPN file
  Future<void> connectToJapanVPN() async {
    try {
      if (_servers.isEmpty) {
        _updateStatus(VPNConnectionState.error, 'No VPN servers available');
        return;
      }

      final japanServer = _servers.first;
      _currentServer = japanServer;

      // Show connecting status
      _updateStatus(VPNConnectionState.connecting);
      await Future.delayed(const Duration(milliseconds: 500));

      // Load OVPN configuration from assets
      final ovpnConfig = await rootBundle.loadString('assets/vpn/jpn_vpn_tcp_fixed.ovpn');

      // Load credentials from assets
      final credentials = await rootBundle.loadString('assets/vpn/jpn_vpn_credentials.txt');
      final credentialLines = credentials.trim().split('\n');
      final username = credentialLines.isNotEmpty ? credentialLines[0].trim() : 'vpn';
      final password = credentialLines.length > 1 ? credentialLines[1].trim() : 'vpn';

      debugPrint('Connecting to Japan VPN server...');
      debugPrint('Username: $username');
      debugPrint('Password: $password');

      // Show authenticating status
      _updateStatus(VPNConnectionState.authenticating);
      await Future.delayed(const Duration(milliseconds: 500));

      // Use the simplest connection method with separate username/password
      debugPrint('Starting connection with:');
      debugPrint('Server: ${japanServer.name}');
      debugPrint('Config lines: ${ovpnConfig.split('\n').length}');
      debugPrint('Config first 100 chars: ${ovpnConfig.substring(0, ovpnConfig.length > 100 ? 100 : ovpnConfig.length)}');

      // Start VPN connection with username and password parameters
      await _openVPN.connect(
        ovpnConfig,
        japanServer.name,
        username: username,
        password: password,
        certIsRequired: false,
      );

      debugPrint('VPN connection initiated successfully');

    } catch (e) {
      debugPrint('Error connecting to Japan VPN: $e');
      _updateStatus(VPNConnectionState.error, e.toString());
    }
  }

  /// Disconnect from VPN
  Future<void> disconnect() async {
    try {
      if (_status.state == VPNConnectionState.disconnected) {
        debugPrint('VPN already disconnected');
        return;
      }

      // Show disconnecting status
      _updateStatus(VPNConnectionState.disconnecting);
      await Future.delayed(const Duration(milliseconds: 500));

      _openVPN.disconnect();

      // Disable proxy when manually disconnecting
      ProxyService.disableProxy();

      _currentServer = null;
      _stopConnectionTimer();

      debugPrint('VPN disconnected successfully');

    } catch (e) {
      debugPrint('Error disconnecting VPN: $e');
      _updateStatus(VPNConnectionState.error, e.toString());
    }
  }

  /// Initialize the VPN service (called from main)
  Future<void> initialize() async {
    try {
      // ✅ Initialize the OpenVPN engine first (as ChatGPT suggested)
      await _openVPN.initialize(
        groupIdentifier: "group.com.example.vpn",
        providerBundleIdentifier: "com.example.vpn.OpenVPNProvider",
        localizedDescription: "Japan VPN Connection",
      );
      debugPrint('✅ OpenVPN engine initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing OpenVPN engine: $e');
    }
  }

  /// Update VPN connection status
  void _updateStatus(VPNConnectionState state, [String? errorMessage]) {
    _status = VPNStatus(
      state: state,
      connectedTime: state == VPNConnectionState.connected ? Duration.zero : _status.connectedTime,
      errorMessage: errorMessage,
    );
    notifyListeners();
    debugPrint('VPN Status updated: $state${errorMessage != null ? ' - $errorMessage' : ''}');
  }

  /// Start connection timer for tracking duration
  void _startConnectionTimer() {
    _stopConnectionTimer();
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      notifyListeners(); // Update UI with new duration
    });
  }

  /// Stop connection timer
  void _stopConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }

  /// Save last connected server
  Future<void> _saveLastConnectedServer() async {
    if (_currentServer == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_connected_server', _currentServer!.name);
    } catch (e) {
      debugPrint('Error saving last connected server: $e');
    }
  }

  /// Load last connected server
  Future<void> _loadLastConnectedServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastServerName = prefs.getString('last_connected_server');

      if (lastServerName != null) {
        debugPrint('Last connected server: $lastServerName');
      }
    } catch (e) {
      debugPrint('Error loading last connected server: $e');
    }
  }

  /// Enable proxy routing for Japan server
  void _enableProxyForJapanServer() {
    try {
      // Use Japan proxy configuration
      final proxyHost = '133.242.26.234'; // Japan proxy server IP
      final proxyPort = 8080;

      ProxyService.enableProxy(proxyHost, proxyPort);
      debugPrint('✅ Enabled Japan proxy routing: $proxyHost:$proxyPort');
    } catch (e) {
      debugPrint('❌ Failed to enable Japan proxy: $e');
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    _stopConnectionTimer();
    super.dispose();
  }
}