// This file contains the implementation of the ServerSelectionScreen, which allows the user to select a V2Ray server to connect to.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proxycloud/models/v2ray_config.dart';
import 'package:proxycloud/providers/v2ray_provider.dart';
import 'package:proxycloud/theme/app_theme.dart';

/// A screen that allows the user to select a V2Ray server to connect to.
class ServerSelectionScreen extends StatefulWidget {
  /// The list of available V2Ray configurations.
  final List<V2RayConfig> configs;

  /// The currently selected V2Ray configuration.
  final V2RayConfig? selectedConfig;

  /// Whether the app is currently connecting to a server.
  final bool isConnecting;

  /// A callback function that is called when a configuration is selected.
  final Future<void> Function(V2RayConfig) onConfigSelected;

  /// Creates a new instance of the [ServerSelectionScreen].
  const ServerSelectionScreen({
    Key? key,
    required this.configs,
    required this.selectedConfig,
    required this.isConnecting,
    required this.onConfigSelected,
  }) : super(key: key);

  @override
  State<ServerSelectionScreen> createState() => _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends State<ServerSelectionScreen> {
  final Map<String, int?> _pings = {};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<V2RayProvider>(context, listen: true);
    final configs = provider.configs;

    List<V2RayConfig> filteredConfigs = List.from(configs);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text(
          'Location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F0F23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23),
              Color(0xFF1A1A3A),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A4A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search location or server..',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Popular Servers Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Servers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Popular Servers List
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final countries = ['Indonesia', 'Singapore', 'United States', 'Germany'];
                  final cities = ['Jakarta', 'Marina Bay', 'Los Angeles', 'Frankfurt'];
                  final flags = ['🇮🇩', '🇸🇬', '🇺🇸', '🇩🇪'];
                  final pings = ['43 ms', '28 ms', '76 ms', '110 ms'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A4A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          flags[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                countries[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                cities[index],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          pings[index],
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 16,
                          height: 12,
                          child: CustomPaint(
                            painter: SignalBarsPainter(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // All Servers Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Servers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // All Servers List
            Expanded(
              child: filteredConfigs.isEmpty
                  ? const Center(
                      child: Text(
                        'No servers available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredConfigs.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final config = filteredConfigs[index];
                        final isSelected = provider.selectedConfig?.id == config.id;

                        // Get country from config name or use default
                        String countryName = config.remark.contains('🇭🇰') ? 'Hongkong' :
                                            config.remark.contains('🇺🇸') ? 'United States' :
                                            config.remark.contains('🇳🇱') ? 'Netherlands' :
                                            config.remark;
                        String locationName = config.address;
                        String flag = config.remark.contains('🇭🇰') ? '🇭🇰' :
                                     config.remark.contains('🇺🇸') ? '🇺🇸' :
                                     config.remark.contains('🇳🇱') ? '🇳🇱' : '🌍';
                        String ping = _pings[config.id] != null && _pings[config.id]! > 0 ?
                                     '${_pings[config.id]}ms' : '-- ms';

                        // Determine if it should show green dot
                        bool showGreenDot = config.remark.contains('Los Angeles');

                        return GestureDetector(
                          onTap: () async {
                            if (widget.isConnecting) return;

                            try {
                              await widget.onConfigSelected(config);
                              if (mounted && Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error selecting server: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A4A),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(
                                color: const Color(0xFF00D4AA),
                                width: 2,
                              ) : null,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            countryName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (showGreenDot) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        locationName,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  ping,
                                  style: TextStyle(
                                    color: _pings[config.id] != null && _pings[config.id]! > 0 ?
                                           Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 16,
                                  height: 12,
                                  child: CustomPaint(
                                    painter: SignalBarsPainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A custom painter for drawing signal bars.
class SignalBarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 5;
    final spacing = barWidth * 0.3;

    for (int i = 0; i < 4; i++) {
      final barHeight = size.height * (i + 1) / 4;
      final x = i * (barWidth + spacing);
      final rect = Rect.fromLTWH(
        x,
        size.height - barHeight,
        barWidth,
        barHeight,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Shows the server selection screen.
void showServerSelectionScreen({
  required BuildContext context,
  required List<V2RayConfig> configs,
  required V2RayConfig? selectedConfig,
  required bool isConnecting,
  required Future<void> Function(V2RayConfig) onConfigSelected,
}) {
  final provider = Provider.of<V2RayProvider>(context, listen: false);
  if (provider.activeConfig != null) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text('Connection Active'),
        content: const Text('Please disconnect first'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServerSelectionScreen(
        configs: configs,
        selectedConfig: selectedConfig,
        isConnecting: isConnecting,
        onConfigSelected: onConfigSelected,
      ),
    ),
  );
}
