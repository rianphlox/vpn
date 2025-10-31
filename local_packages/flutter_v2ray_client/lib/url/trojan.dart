import 'package:flutter_v2ray_client/url/url.dart';

/// Trojan URL parser and adapter to produce V2Ray configuration pieces.
///
/// It parses a `trojan://` share link into structured fields and exposes
/// outbound and stream settings compatible with the V2Ray core.
class TrojanURL extends V2RayURL {
  /// Creates a TrojanURL by parsing the provided trojan share link string.
  ///
  /// Throws [ArgumentError] if the url does not start with `trojan://` or
  /// cannot be decoded into a valid URI.
  TrojanURL({required super.url}) {
    if (!url.startsWith('trojan://')) {
      throw ArgumentError('url is invalid');
    }
    final temp = Uri.tryParse(url);
    if (temp == null) {
      throw ArgumentError('url is invalid');
    }
    uri = temp;
    if (uri.queryParameters.isNotEmpty) {
      final sni = super.populateTransportSettings(
        transport: uri.queryParameters['type'] ?? 'tcp',
        headerType: uri.queryParameters['headerType'],
        host: uri.queryParameters['host'],
        path: uri.queryParameters['path'],
        seed: uri.queryParameters['seed'],
        quicSecurity: uri.queryParameters['quicSecurity'],
        key: uri.queryParameters['key'],
        mode: uri.queryParameters['mode'],
        serviceName: uri.queryParameters['serviceName'],
      );

      super.populateTlsSettings(
        streamSecurity: uri.queryParameters['security'] ?? 'tls',
        allowInsecure: allowInsecure,
        sni: uri.queryParameters['sni'] ?? sni,
        fingerprint:
            streamSetting['tlsSettings']?['fingerprint'] ?? 'randomized',
        alpns: uri.queryParameters['alpn'],
        publicKey: null,
        shortId: null,
        spiderX: null,
      );
      flow = uri.queryParameters['flow'] ?? '';
    } else {
      super.populateTlsSettings(
        streamSecurity: 'tls',
        allowInsecure: allowInsecure,
        sni: '',
        fingerprint:
            streamSetting['tlsSettings']?['fingerprint'] ?? 'randomized',
        alpns: null,
        publicKey: null,
        shortId: null,
        spiderX: null,
      );
    }
  }

  /// Flow parameter for the trojan connection.
  String flow = '';

  /// The parsed URI object from the trojan URL.
  late final Uri uri;

  /// Server address extracted from the URI host.
  @override
  String get address => uri.host;

  /// Server port parsed from the URI. Falls back to [super.port] if absent.
  @override
  int get port => uri.hasPort ? uri.port : super.port;

  /// Human-readable remark decoded from the URI fragment.
  @override
  String get remark => Uri.decodeFull(uri.fragment.replaceAll('+', '%20'));

  /// Outbound configuration map for the trojan protocol used by V2Ray core.
  @override
  Map<String, dynamic> get outbound1 => {
        'tag': 'proxy',
        'protocol': 'trojan',
        'settings': {
          'vnext': null,
          'servers': [
            {
              'address': address,
              'method': 'chacha20-poly1305',
              'ota': false,
              'password': uri.userInfo,
              'port': port,
              'level': level,
              'email': null,
              'flow': flow,
              'ivCheck': null,
              'users': null
            }
          ],
          'response': null,
          'network': null,
          'address': null,
          'port': null,
          'domainStrategy': null,
          'redirect': null,
          'userLevel': null,
          'inboundTag': null,
          'secretKey': null,
          'peers': null
        },
        'streamSettings': streamSetting,
        'proxySettings': null,
        'sendThrough': null,
        'mux': {'enabled': false, 'concurrency': 8}
      };
}
