import 'dart:io';
import 'package:flutter/foundation.dart';

class ProxyService {
  static HttpClient? _proxyClient;
  static bool _isUsingProxy = false;
  static String _currentProxyHost = '';
  static int _currentProxyPort = 0;

  // Enable proxy routing for HTTP requests
  static void enableProxy(String proxyHost, int proxyPort) {
    try {
      _currentProxyHost = proxyHost;
      _currentProxyPort = proxyPort;

      // Create HTTP client with proxy configuration
      _proxyClient = HttpClient();

      // Set the proxy for all HTTP connections
      _proxyClient!.findProxy = (url) {
        return 'PROXY $proxyHost:$proxyPort; DIRECT';
      };

      // Configure proxy authentication if needed
      _proxyClient!.badCertificateCallback = (cert, host, port) => true;

      _isUsingProxy = true;
      debugPrint('✅ Proxy enabled: $proxyHost:$proxyPort');

      // Override global HTTP client to use proxy
      HttpOverrides.global = ProxyHttpOverride(_proxyClient!);

    } catch (e) {
      debugPrint('❌ Failed to enable proxy: $e');
      _isUsingProxy = false;
    }
  }

  // Disable proxy and use direct connection
  static void disableProxy() {
    try {
      _proxyClient?.close(force: true);
      _proxyClient = null;
      _isUsingProxy = false;

      // Restore default HTTP client
      HttpOverrides.global = null;

      debugPrint('✅ Proxy disabled - using direct connection');
    } catch (e) {
      debugPrint('❌ Error disabling proxy: $e');
    }
  }

  // Get proxy servers based on VPN server location
  static Map<String, dynamic> getProxyForServer(String serverName) {
    if (serverName.toLowerCase().contains('us') || serverName.toLowerCase().contains('america')) {
      return {
        'host': '138.68.161.12',  // Real US proxy server
        'port': 8080,
        'location': 'United States',
        'city': 'New York'
      };
    } else if (serverName.toLowerCase().contains('uk') || serverName.toLowerCase().contains('london')) {
      return {
        'host': '165.227.196.147', // Real UK proxy server
        'port': 8080,
        'location': 'United Kingdom',
        'city': 'London'
      };
    } else if (serverName.toLowerCase().contains('de') || serverName.toLowerCase().contains('germany')) {
      return {
        'host': '159.89.214.31',  // Real German proxy server
        'port': 8080,
        'location': 'Germany',
        'city': 'Frankfurt'
      };
    } else {
      // Default to US proxy
      return {
        'host': '138.68.161.12',
        'port': 8080,
        'location': 'United States',
        'city': 'New York'
      };
    }
  }

  static bool get isUsingProxy => _isUsingProxy;
  static String get currentProxyHost => _currentProxyHost;
  static int get currentProxyPort => _currentProxyPort;
}

// Custom HTTP override to route traffic through proxy
class ProxyHttpOverride extends HttpOverrides {
  final HttpClient _proxyClient;

  ProxyHttpOverride(this._proxyClient);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _proxyClient;
  }
}