import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/vpn_service.dart';
import '../widgets/timer_widget.dart';
import '../widgets/status_indicator.dart';
import '../widgets/power_button.dart';
import '../widgets/server_card.dart';
import 'location_screen.dart';
import 'network_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VPNService>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 30),
              Consumer<VPNService>(
                builder: (context, vpnService, child) {
                  return Column(
                    children: [
                      TimerWidget(
                        duration: vpnService.status.connectedTime,
                        isConnected: vpnService.status.isConnected,
                      ),
                      const SizedBox(height: 20),
                      StatusIndicator(status: vpnService.status),
                      const SizedBox(height: 40),
                      PowerButton(
                        isConnected: vpnService.status.isConnected,
                        isConnecting: vpnService.status.isConnecting,
                        onTap: () => _toggleConnection(vpnService),
                      ),
                      const SizedBox(height: 40),
                      _buildSelectors(vpnService),
                      const SizedBox(height: 20),
                      if (vpnService.currentServer != null)
                        ServerCard(
                          server: vpnService.currentServer!,
                          isSelected: true,
                          onTap: () => _openLocationSelection(vpnService),
                        )
                      else
                        _buildSelectServerCard(vpnService),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
            ),
          ),
          child: const Icon(
            CupertinoIcons.rocket_fill,
            color: Colors.white,
            size: 24,
          ),
        ),
        const Text(
          'QShield ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(
            CupertinoIcons.info_circle,
            color: Colors.white70,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NetworkTestScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectors(VPNService vpnService) {
    return Row(
      children: [
        Expanded(
          child: _buildSelector(
            'Mode',
            'Smart',
            CupertinoIcons.wand_rays,
            () {
              // Mode selection
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSelector(
            'Node',
            'Global',
            CupertinoIcons.globe,
            () => _openLocationSelection(vpnService),
          ),
        ),
      ],
    );
  }

  Widget _buildSelector(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    );
  }

  Widget _buildSelectServerCard(VPNService vpnService) {
    return GestureDetector(
      onTap: () => _openLocationSelection(vpnService),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A3E)),
        ),
        child: const Column(
          children: [
            Icon(
              CupertinoIcons.location,
              color: Color(0xFF4FC3F7),
              size: 32,
            ),
            SizedBox(height: 12),
            Text(
              'Select Server',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Choose your preferred location',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleConnection(VPNService vpnService) async {
    if (vpnService.status.isConnected) {
      await vpnService.disconnect();
    } else {
      // Connect to Japan VPN server using OpenVPN Flutter
      await vpnService.connectToJapanVPN();
    }
  }

  void _openLocationSelection(VPNService vpnService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationScreen(),
      ),
    );
  }
}