import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import '../models/vpn_server.dart';
import '../models/vpn_status.dart';

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
    } else if (statusString.contains('disconnected')) {
      _updateStatus(VPNConnectionState.disconnected);
      _stopConnectionTimer();
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
      _updateStatus(VPNConnectionState.connecting);

      // Load OVPN configuration from assets
      final ovpnConfig = await rootBundle.loadString('assets/vpn/jpn_vpn_tcp_fixed.ovpn');

      // Load credentials from assets
      final credentials = await rootBundle.loadString('assets/vpn/jpn_vpn_credentials.txt');
      final credentialLines = credentials.trim().split('\\n');
      final username = credentialLines.isNotEmpty ? credentialLines[0] : 'vpn';
      final password = credentialLines.length > 1 ? credentialLines[1] : 'vpn';

      debugPrint('Connecting to Japan VPN server...');
      debugPrint('Username: $username');

      // Start VPN connection
      await _openVPN.connect(
        ovpnConfig,
        japanServer.name,
        username: username,
        password: password,
        bypassPackages: [], // Optional: apps to bypass VPN
        certIsRequired: false, // Set based on your OVPN config
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

      _updateStatus(VPNConnectionState.disconnecting);
      _openVPN.disconnect();

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
      // OpenVPN Flutter handles permissions internally
      debugPrint('VPN service initialized with Japan VPN server');
    } catch (e) {
      debugPrint('Error initializing VPN service: $e');
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

  /// Clean up resources
  @override
  void dispose() {
    _stopConnectionTimer();
    super.dispose();
  }
}