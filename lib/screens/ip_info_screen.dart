import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/v2ray_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class IpInfoScreen extends StatefulWidget {
  const IpInfoScreen({super.key});

  @override
  State<IpInfoScreen> createState() => _IpInfoScreenState();
}

class _IpInfoScreenState extends State<IpInfoScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _ipData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchIpInfo();
  }

  Future<void> _fetchIpInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Provider.of<V2RayProvider>(
        context,
        listen: false,
      ).v2rayService.fetchIpInfo();

      if (response.success) {
        // Fetch the full details from the API
        final fullResponse = await _fetchFullIpDetails();
        setState(() {
          _ipData = fullResponse;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.errorMessage ?? 'Failed to fetch IP information';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchFullIpDetails() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipleak.net/json/'))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                'Network timeout: Check your internet connection',
              );
            },
          );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch full IP details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr('ip_info.title')),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchIpInfo,
            tooltip: context.tr('common.refresh'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              context.tr('common.error'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchIpInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      );
    }

    if (_ipData == null) {
      return Center(
        child: Text(
          context.tr('ip_info.no_info_available'),
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildLocationCard(),
          const SizedBox(height: 16),
          _buildNetworkCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ip_info.summary'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.ip_address'),
              _ipData!['ip'] ?? context.tr('common.unknown'),
            ),
            _buildInfoRow(
              context.tr('ip_info.location'),
              '${_ipData!['country_name'] ?? context.tr('common.unknown')} - ${_ipData!['city_name'] ?? context.tr('common.unknown')}',
            ),
            _buildInfoRow(
              context.tr('ip_info.isp'),
              _ipData!['isp_name'] ?? context.tr('common.unknown'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ip_info.location'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.country'),
              '${_ipData!['country_name'] ?? context.tr('common.unknown')} (${_ipData!['country_code'] ?? context.tr('common.unknown')})',
            ),
            _buildInfoRow(
              context.tr('ip_info.region'),
              '${_ipData!['region_name'] ?? context.tr('common.unknown')} (${_ipData!['region_code'] ?? context.tr('common.unknown')})',
            ),
            _buildInfoRow(
              context.tr('ip_info.city'),
              _ipData!['city_name'] ?? context.tr('common.unknown'),
            ),
            _buildInfoRow(
              context.tr('ip_info.continent'),
              '${_ipData!['continent_name'] ?? context.tr('common.unknown')} (${_ipData!['continent_code'] ?? context.tr('common.unknown')})',
            ),
            _buildInfoRow(
              context.tr('ip_info.postal_code'),
              _ipData!['postal_code']?.toString() ??
                  context.tr('common.unknown'),
            ),
            _buildInfoRow(
              context.tr('ip_info.time_zone'),
              _ipData!['time_zone'] ?? context.tr('common.unknown'),
            ),
            _buildInfoRow(
              context.tr('ip_info.coordinates'),
              '${_ipData!['latitude']?.toString() ?? context.tr('common.unknown')}, ${_ipData!['longitude']?.toString() ?? context.tr('common.unknown')}',
            ),
            _buildInfoRow(
              context.tr('ip_info.accuracy_radius'),
              '${_ipData!['accuracy_radius']?.toString() ?? context.tr('common.unknown')} ${context.tr('ip_info.km')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard() {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ip_info.network'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context.tr('ip_info.isp'),
              _ipData!['isp_name'] ?? context.tr('common.unknown'),
            ),
            _buildInfoRow(
              context.tr('ip_info.as_number'),
              _ipData!['as_number']?.toString() ?? context.tr('common.unknown'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
