class VPNServer {
  final String name;
  final String country;
  final String city;
  final String flagCode;
  final int latency;
  final int signalStrength;
  final String ovpnConfig;
  final String ip;
  final String hostname;
  final double uptime;
  final String countryShort;

  VPNServer({
    required this.name,
    required this.country,
    required this.city,
    required this.flagCode,
    required this.latency,
    required this.signalStrength,
    required this.ovpnConfig,
    required this.ip,
    this.hostname = '',
    this.uptime = 0.0,
    this.countryShort = '',
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
      hostname: json['HostName'] ?? '',
      uptime: double.tryParse(json['Uptime']?.toString() ?? '0') ?? 0.0,
      countryShort: json['CountryShort'] ?? '',
    );
  }

  factory VPNServer.fromVPNGateCSV(List<String> csvFields) {
    if (csvFields.length < 15) {
      throw ArgumentError('Invalid CSV data: insufficient fields');
    }

    return VPNServer(
      hostname: csvFields[0],
      ip: csvFields[1],
      latency: int.tryParse(csvFields[3]) ?? 0,
      signalStrength: (int.tryParse(csvFields[2]) ?? 0) ~/ 1000000,
      country: csvFields[6],
      countryShort: csvFields[6],
      city: csvFields[5],
      flagCode: csvFields[6].toLowerCase(),
      uptime: double.tryParse(csvFields[7]) ?? 0.0,
      ovpnConfig: csvFields[14],
      name: csvFields[0],
    );
  }

  String get flagEmoji {
    final codePoints = flagCode.toUpperCase().codeUnits
        .map((code) => 0x1F1E6 + (code - 0x41))
        .toList();
    return String.fromCharCodes(codePoints);
  }
}