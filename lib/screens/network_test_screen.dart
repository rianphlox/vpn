import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../l10n/app_localizations.dart';

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({Key? key}) : super(key: key);

  @override
  _NetworkTestScreenState createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _networkInfo;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://ifconfig.co/json'),
        headers: {'User-Agent': 'QShield-VPN/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _networkInfo = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load network info: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Network Information',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: Colors.white70),
            onPressed: _loadNetworkInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF4FC3F7),
            ),
            SizedBox(height: 16),
            Text(
              'Loading network information...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load network information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadNetworkInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        _buildInfoCard(
          'IP Address',
          _networkInfo?['ip']?.toString() ?? 'Unknown',
          CupertinoIcons.wifi,
          Colors.blueAccent,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Internet Provider',
          _getProviderInfo(),
          CupertinoIcons.building_2_fill,
          Colors.greenAccent,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Location',
          _getLocationInfo(),
          CupertinoIcons.location_solid,
          Colors.orangeAccent,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Timezone',
          _networkInfo?['time_zone']?.toString() ?? 'Unknown',
          CupertinoIcons.time,
          Colors.purpleAccent,
        ),
        const SizedBox(height: 24),
        _buildDetailSection(),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    if (_networkInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (_networkInfo!['user_agent'] != null)
            _buildDetailRow('User Agent', _networkInfo!['user_agent'].toString()),
          if (_networkInfo!['country_code'] != null)
            _buildDetailRow('Country Code', _networkInfo!['country_code'].toString()),
          if (_networkInfo!['asn'] != null)
            _buildDetailRow('ASN', _networkInfo!['asn'].toString()),
          if (_networkInfo!['asn_org'] != null)
            _buildDetailRow('ASN Organization', _networkInfo!['asn_org'].toString()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderInfo() {
    if (_networkInfo == null) return 'Unknown';

    final asn = _networkInfo!['asn'];
    final asnOrg = _networkInfo!['asn_org'];

    if (asnOrg != null && asn != null) {
      return '${asnOrg.toString()} (AS${asn.toString()})';
    } else if (asnOrg != null) {
      return asnOrg.toString();
    } else if (asn != null) {
      return 'AS${asn.toString()}';
    } else {
      return 'Unknown';
    }
  }

  String _getLocationInfo() {
    if (_networkInfo == null) return 'Unknown';

    final city = _networkInfo!['city'];
    final region = _networkInfo!['region'];
    final country = _networkInfo!['country'];

    List<String> locationParts = [];
    if (city != null) locationParts.add(city.toString());
    if (region != null) locationParts.add(region.toString());
    if (country != null) locationParts.add(country.toString());

    return locationParts.isNotEmpty ? locationParts.join(', ') : 'Unknown';
  }
}