import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vpn_server.dart';
import '../models/vpn_status.dart';
import '../models/vpnbook_servers.dart';

class VPNService extends ChangeNotifier {
  static final VPNService _instance = VPNService._internal();
  factory VPNService() => _instance;
  VPNService._internal() {
    _setupMethodChannel();
    _loadLastConnectedServer();
  }

  static const MethodChannel _vpnChannel = MethodChannel('com.example.vpn/vpn');

  VPNStatus _status = VPNStatus(state: VPNConnectionState.disconnected);
  final List<VPNServer> _servers = [];
  VPNServer? _currentServer;
  Timer? _connectionTimer;
  bool _vpnPermissionGranted = false;

  VPNStatus get status => _status;
  List<VPNServer> get servers => _servers;
  VPNServer? get currentServer => _currentServer;
  bool get vpnPermissionGranted => _vpnPermissionGranted;

  void _setupMethodChannel() {
    _vpnChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'vpnStatus':
          final connected = call.arguments['connected'] as bool;
          final message = call.arguments['message'] as String;

          if (connected) {
            _updateStatus(VPNConnectionState.connected);
            _startConnectionTimer();
          } else {
            _updateStatus(VPNConnectionState.disconnected);
            _stopConnectionTimer();
            if (_status.state == VPNConnectionState.disconnecting) {
              _currentServer = null;
            }
          }

          debugPrint('VPN Status: $message');
          break;

        case 'vpnPermissionGranted':
          final granted = call.arguments as bool;
          _vpnPermissionGranted = granted;

          if (granted && _currentServer != null) {
            await _connectToNativeVpn(_currentServer!);
          } else if (!granted) {
            _updateStatus(VPNConnectionState.error, 'VPN permission denied');
          }
          break;
      }
    });
  }

  Future<void> initialize() async {
    try {
      // Load predefined premium servers first
      _loadPredefinedServers();

      // Then try to fetch additional VPNGate servers
      await fetchVPNGateServers();
      await _prepareVpn();
    } catch (e) {
      debugPrint('Error initializing VPN service: $e');
    }
  }

  void _loadPredefinedServers() {
    final predefinedServers = VPNBookServers.getPredefinedServers();
    _servers.addAll(predefinedServers);
    notifyListeners();
    debugPrint('Loaded ${predefinedServers.length} predefined servers');
  }

  Future<bool> _prepareVpn() async {
    try {
      final result = await _vpnChannel.invokeMethod('prepareVpn');
      _vpnPermissionGranted = result as bool;
      return _vpnPermissionGranted;
    } catch (e) {
      debugPrint('Error preparing VPN: $e');
      return false;
    }
  }

  Future<void> fetchVPNGateServers() async {
    try {
      debugPrint('Fetching VPN Gate servers...');
      final response = await http.get(
        Uri.parse('https://www.vpngate.net/api/iphone/'),
        headers: {'User-Agent': 'VPNGate API Client'},
      );

      if (response.statusCode == 200) {
        final csvData = response.body;
        final lines = csvData.split('\n');

        final vpnGateServers = <VPNServer>[];

        for (int i = 2; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty || line.startsWith('*') || line.startsWith('#')) continue;

          try {
            final csvFields = const CsvToListConverter().convert(line)[0];
            if (csvFields.length >= 15) {
              final server = VPNServer.fromVPNGateCSV(
                csvFields.map((field) => field.toString()).toList()
              );

              if (server.ovpnConfig.isNotEmpty &&
                  server.latency > 0 &&
                  server.latency < 1000 &&
                  server.uptime > 0) {
                vpnGateServers.add(server);
              }
            }
          } catch (e) {
            debugPrint('Error parsing VPN Gate server: $e');
          }
        }

        _servers.clear();
        _loadPredefinedServers();
        _servers.addAll(vpnGateServers);
        _servers.sort((a, b) => a.latency.compareTo(b.latency));

        debugPrint('Loaded ${vpnGateServers.length} VPN Gate servers');
        notifyListeners();
      } else {
        debugPrint('Failed to fetch VPN Gate servers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching VPNGate servers: $e');
      _loadPredefinedServers();
    }
  }

  Future<void> connectToVPNGate(VPNServer server) async {
    try {
      _updateStatus(VPNConnectionState.connecting);
      _currentServer = server;

      if (!_vpnPermissionGranted) {
        final prepared = await _prepareVpn();
        if (!prepared) {
          // Will wait for permission callback
          return;
        }
      }

      await _connectToNativeVpn(server);
    } catch (e) {
      _updateStatus(VPNConnectionState.error, e.toString());
    }
  }

  Future<void> _connectToNativeVpn(VPNServer server) async {
    try {
      String decodedConfig;
      String username;
      String password;
      int port;

      // Check if this is a VPNBook server
      if (server.name.startsWith('vpnbook-')) {
        // Use VPNBook configuration and credentials
        decodedConfig = VPNBookServers.getRawOVPNConfig(server.name);
        username = VPNBookServers.username;
        password = VPNBookServers.password;
        port = 80; // VPNBook uses port 80 for TCP
        debugPrint('Using VPNBook server: ${server.name}');
      } else {
        // Use VPNGate configuration and credentials
        decodedConfig = utf8.decode(base64.decode(server.ovpnConfig));
        username = 'vpn';
        password = 'vpn';
        port = 1194; // Default OpenVPN port
        debugPrint('Using VPNGate server: ${server.name}');
      }

      await _vpnChannel.invokeMethod('connectVpn', {
        'serverConfig': decodedConfig,
        'serverHost': server.ip,
        'serverPort': port,
        'username': username,
        'password': password,
      });

      debugPrint('Connecting to VPN server: ${server.name} (${server.ip}:$port)');
    } catch (e) {
      _updateStatus(VPNConnectionState.error, 'Failed to connect: ${e.toString()}');
    }
  }

  Future<void> disconnect() async {
    try {
      _updateStatus(VPNConnectionState.disconnecting);

      await _vpnChannel.invokeMethod('disconnectVpn');

      debugPrint('Disconnecting from VPN');
    } catch (e) {
      _updateStatus(VPNConnectionState.error, e.toString());
    }
  }

  void _updateStatus(VPNConnectionState state, [String? errorMessage]) {
    _status = VPNStatus(
      state: state,
      connectedTime: _status.connectedTime,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  void _startConnectionTimer() {
    _stopConnectionTimer();
    final startTime = DateTime.now();

    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      _status = _status.copyWith(connectedTime: elapsed);
      notifyListeners();
    });
  }

  void _stopConnectionTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
    _status = _status.copyWith(connectedTime: Duration.zero);
  }

  void setCurrentServer(VPNServer server) {
    _currentServer = server;
    _saveLastConnectedServer(server);
    notifyListeners();
  }

  Future<void> _saveLastConnectedServer(VPNServer server) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverData = {
        'name': server.name,
        'country': server.country,
        'city': server.city,
        'flagCode': server.flagCode,
        'latency': server.latency,
        'signalStrength': server.signalStrength,
        'ovpnConfig': server.ovpnConfig,
        'ip': server.ip,
        'hostname': server.hostname,
        'uptime': server.uptime,
        'countryShort': server.countryShort,
      };
      await prefs.setString('last_connected_server', jsonEncode(serverData));
    } catch (e) {
      debugPrint('Error saving last connected server: $e');
    }
  }

  Future<void> _loadLastConnectedServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverJson = prefs.getString('last_connected_server');
      if (serverJson != null) {
        final serverData = jsonDecode(serverJson) as Map<String, dynamic>;
        _currentServer = VPNServer(
          name: serverData['name'] ?? '',
          country: serverData['country'] ?? '',
          city: serverData['city'] ?? '',
          flagCode: serverData['flagCode'] ?? '',
          latency: serverData['latency'] ?? 0,
          signalStrength: serverData['signalStrength'] ?? 0,
          ovpnConfig: serverData['ovpnConfig'] ?? '',
          ip: serverData['ip'] ?? '',
          hostname: serverData['hostname'] ?? '',
          uptime: serverData['uptime']?.toDouble() ?? 0.0,
          countryShort: serverData['countryShort'] ?? '',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading last connected server: $e');
    }
  }

  Future<void> reconnectToLastServer() async {
    if (_currentServer != null) {
      await connectToVPNGate(_currentServer!);
    }
  }

  bool get hasServers => _servers.isNotEmpty;

  @override
  void dispose() {
    _stopConnectionTimer();
    super.dispose();
  }
}