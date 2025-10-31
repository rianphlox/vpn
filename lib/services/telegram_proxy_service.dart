// This file contains the implementation of the TelegramProxyService, which is responsible for fetching Telegram proxies from a remote server.

import 'package:http/http.dart' as http;
import '../models/telegram_proxy.dart';

/// A service that fetches Telegram proxies from a remote server.
class TelegramProxyService {
  static const String proxyUrl =
      'https://raw.githubusercontent.com/hookzof/socks5_list/master/tg/mtproto.json';

  // Singleton pattern
  static final TelegramProxyService _instance =
      TelegramProxyService._internal();
  factory TelegramProxyService() => _instance;

  TelegramProxyService._internal();

  /// Fetches the list of Telegram proxies from the remote server.
  Future<List<TelegramProxy>> fetchProxies() async {
    try {
      final response = await http.get(Uri.parse(proxyUrl)).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception('Network timeout: Check your internet connection');
            },
          );

      if (response.statusCode == 200) {
        return parseTelegramProxies(response.body);
      } else {
        throw Exception('Failed to load proxies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching proxies: $e');
    }
  }
}