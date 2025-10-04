class VPNServer {
  final String name;
  final String country;
  final String city;
  final String flagCode;
  final int latency;
  final int signalStrength;
  final String ovpnConfig;
  final String ip;

  VPNServer({
    required this.name,
    required this.country,
    required this.city,
    required this.flagCode,
    required this.latency,
    required this.signalStrength,
    required this.ovpnConfig,
    required this.ip,
  });

  factory VPNServer.fromJson(Map<String, dynamic> json) {
    return VPNServer(
      name: json['HostName'] ?? '',
      country: json['CountryLong'] ?? '',
      city: json['CountryShort'] ?? '',
      flagCode: json['CountryShort']?.toLowerCase() ?? '',
      latency: int.tryParse(json['Ping']?.toString() ?? '0') ?? 0,
      signalStrength: int.tryParse(json['Score']?.toString() ?? '0') ?? 0,
      ovpnConfig: json['OpenVPN_ConfigData_Base64'] ?? '',
      ip: json['IP'] ?? '',
    );
  }

  String get flagEmoji {
    final codePoints = flagCode.toUpperCase().codeUnits
        .map((code) => 0x1F1E6 + (code - 0x41))
        .toList();
    return String.fromCharCodes(codePoints);
  }
}