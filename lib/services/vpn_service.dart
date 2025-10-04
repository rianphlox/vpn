import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/vpn_server.dart';
import '../models/vpn_status.dart';
import '../models/vpnbook_servers.dart';

class VPNService extends ChangeNotifier {
  static final VPNService _instance = VPNService._internal();
  factory VPNService() => _instance;
  VPNService._internal() {
    _setupMethodChannel();
  }

  static const MethodChannel _vpnChannel = MethodChannel('com.example.vpn/vpn');

  VPNStatus _status = VPNStatus(state: VPNConnectionState.disconnected);
  List<VPNServer> _servers = [];
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
      final response = await http.get(
        Uri.parse('https://www.vpngate.net/api/iphone/'),
        headers: {'User-Agent': 'VPNGate API Client'},
      );

      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        _servers.clear();

        for (int i = 2; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final parts = line.split(',');
          if (parts.length >= 14) {
            try {
              final server = VPNServer(
                name: parts[0],
                country: parts[6],
                city: parts[5],
                flagCode: parts[6].toLowerCase(),
                latency: int.tryParse(parts[3]) ?? 0,
                signalStrength: (int.tryParse(parts[2]) ?? 0) ~/ 1000000,
                ovpnConfig: parts[14],
                ip: parts[1],
              );

              if (server.ovpnConfig.isNotEmpty && server.latency > 0) {
                _servers.add(server);
              }
            } catch (e) {
              debugPrint('Error parsing server data: $e');
            }
          }
        }

        _servers.sort((a, b) => a.latency.compareTo(b.latency));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching VPNGate servers: $e');
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
    notifyListeners();
  }

  @override
  void dispose() {
    _stopConnectionTimer();
    super.dispose();
  }
}