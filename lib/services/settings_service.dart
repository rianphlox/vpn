import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal() {
    _loadSettings();
  }

  bool _autoConnect = false;
  bool _killSwitch = true;
  bool _dnsProtection = true;
  bool _notifications = true;
  String _selectedProtocol = 'OpenVPN';
  String _selectedLanguage = 'en';
  List<Map<String, dynamic>> _connectionLogs = [];

  bool get autoConnect => _autoConnect;
  bool get killSwitch => _killSwitch;
  bool get dnsProtection => _dnsProtection;
  bool get notifications => _notifications;
  String get selectedProtocol => _selectedProtocol;
  String get selectedLanguage => _selectedLanguage;
  List<Map<String, dynamic>> get connectionLogs => List.unmodifiable(_connectionLogs);

  Locale get currentLocale {
    switch (_selectedLanguage) {
      case 'es':
        return const Locale('es');
      case 'de':
        return const Locale('de');
      case 'en':
      default:
        return const Locale('en');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoConnect = prefs.getBool('auto_connect') ?? false;
      _killSwitch = prefs.getBool('kill_switch') ?? true;
      _dnsProtection = prefs.getBool('dns_protection') ?? true;
      _notifications = prefs.getBool('notifications') ?? true;
      _selectedProtocol = prefs.getString('selected_protocol') ?? 'OpenVPN';
      _selectedLanguage = prefs.getString('selected_language') ?? 'en';
      _loadConnectionLogs();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setAutoConnect(bool value) async {
    if (_autoConnect != value) {
      _autoConnect = value;
      await _saveBoolSetting('auto_connect', value);
      notifyListeners();
    }
  }

  Future<void> setKillSwitch(bool value) async {
    if (_killSwitch != value) {
      _killSwitch = value;
      await _saveBoolSetting('kill_switch', value);
      notifyListeners();
    }
  }

  Future<void> setDnsProtection(bool value) async {
    if (_dnsProtection != value) {
      _dnsProtection = value;
      await _saveBoolSetting('dns_protection', value);
      notifyListeners();
    }
  }

  Future<void> setNotifications(bool value) async {
    if (_notifications != value) {
      _notifications = value;
      await _saveBoolSetting('notifications', value);
      notifyListeners();
    }
  }

  Future<void> setSelectedProtocol(String value) async {
    if (_selectedProtocol != value) {
      _selectedProtocol = value;
      await _saveStringSetting('selected_protocol', value);
      notifyListeners();
    }
  }

  Future<void> setSelectedLanguage(String value) async {
    if (_selectedLanguage != value) {
      _selectedLanguage = value;
      await _saveStringSetting('selected_language', value);
      notifyListeners();
    }
  }

  void addConnectionLog(String server, String protocol, DateTime connectTime, DateTime? disconnectTime, String status) {
    final log = {
      'server': server,
      'protocol': protocol,
      'connectTime': connectTime.toIso8601String(),
      'disconnectTime': disconnectTime?.toIso8601String(),
      'status': status,
      'duration': disconnectTime?.difference(connectTime).inMinutes,
    };

    _connectionLogs.insert(0, log);
    if (_connectionLogs.length > 50) {
      _connectionLogs.removeRange(50, _connectionLogs.length);
    }

    _saveConnectionLogs();
    notifyListeners();
  }

  List<Map<String, dynamic>> getLastConnections({int limit = 10}) {
    return _connectionLogs.take(limit).toList();
  }

  void _loadConnectionLogs() {
    // For now, add some sample data
    _connectionLogs = [
      {
        'server': 'US East (New York)',
        'protocol': 'OpenVPN',
        'connectTime': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'disconnectTime': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'status': 'Completed',
        'duration': 60,
      },
      {
        'server': 'UK (London)',
        'protocol': 'OpenVPN',
        'connectTime': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'disconnectTime': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'status': 'Completed',
        'duration': 45,
      },
      {
        'server': 'Germany (Frankfurt)',
        'protocol': 'WireGuard',
        'connectTime': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        'disconnectTime': DateTime.now().subtract(const Duration(hours: 5, minutes: 30)).toIso8601String(),
        'status': 'Completed',
        'duration': 30,
      },
      {
        'server': 'Japan (Tokyo)',
        'protocol': 'OpenVPN',
        'connectTime': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
        'disconnectTime': DateTime.now().subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
        'status': 'Completed',
        'duration': 120,
      },
      {
        'server': 'Canada (Toronto)',
        'protocol': 'IKEv2',
        'connectTime': DateTime.now().subtract(const Duration(days: 1, hours: 6)).toIso8601String(),
        'disconnectTime': DateTime.now().subtract(const Duration(days: 1, hours: 4)).toIso8601String(),
        'status': 'Completed',
        'duration': 90,
      },
    ];
  }

  Future<void> _saveConnectionLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _connectionLogs.map((log) => log.toString()).toList();
      await prefs.setStringList('connection_logs', logsJson);
    } catch (e) {
      debugPrint('Error saving connection logs: $e');
    }
  }

  Future<void> _saveBoolSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
    }
  }

  Future<void> _saveStringSetting(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error saving setting $key: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear only cache-related keys, preserve settings
      final keysToRemove = <String>[];
      for (String key in prefs.getKeys()) {
        if (key.startsWith('cache_') || key.startsWith('temp_')) {
          keysToRemove.add(key);
        }
      }

      for (String key in keysToRemove) {
        await prefs.remove(key);
      }

      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}