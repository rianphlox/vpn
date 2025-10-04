import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/vpn_server.dart';

class ServerCard extends StatelessWidget {
  final VPNServer server;
  final bool isSelected;
  final VoidCallback? onTap;

  const ServerCard({
    Key? key,
    required this.server,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3460) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4FC3F7) : const Color(0xFF2A2A3E),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2A2A3E),
              ),
              child: Center(
                child: Text(
                  server.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    server.country,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    server.city,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${server.latency}ms',
                      style: TextStyle(
                        color: _getLatencyColor(server.latency),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSignalBars(server.signalStrength),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalBars(int strength) {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index < (strength / 25).clamp(1, 4);
        return Container(
          margin: const EdgeInsets.only(left: 2),
          width: 3,
          height: 12 + (index * 2.0),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4CAF50) : Colors.white24,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getLatencyColor(int latency) {
    if (latency < 50) return const Color(0xFF4CAF50);
    if (latency < 100) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }
}