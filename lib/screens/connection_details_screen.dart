// This file contains the implementation of the ConnectionDetailsScreen, which displays details about the current VPN connection.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/v2ray_provider.dart';

/// A screen that displays details about the current VPN connection.
class ConnectionDetailsScreen extends StatefulWidget {
  const ConnectionDetailsScreen({super.key});

  @override
  State<ConnectionDetailsScreen> createState() =>
      _ConnectionDetailsScreenState();
}

class _ConnectionDetailsScreenState extends State<ConnectionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<V2RayProvider>(
      builder: (context, provider, _) {
        final isConnected = provider.activeConfig != null;
        final v2rayService = provider.v2rayService;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F23),
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
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Connection Detail',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.star_outline, color: Colors.orange),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Connection Timer
                  const Text(
                    'Connecting time',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      return Text(
                        isConnected
                            ? v2rayService.getFormattedConnectedTime()
                            : '01:24:20',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Connection Speed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.download,
                                color: Color(0xFF00D4AA),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Download',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder(
                            stream: Stream.periodic(const Duration(seconds: 1)),
                            builder: (context, snapshot) {
                              return Text(
                                isConnected
                                    ? v2rayService.getFormattedDownload()
                                    : '30 Mbps',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.upload,
                                color: Color(0xFF00D4AA),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Upload',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder(
                            stream: Stream.periodic(const Duration(seconds: 1)),
                            builder: (context, snapshot) {
                              return Text(
                                isConnected
                                    ? v2rayService.getFormattedUpload()
                                    : '67 Mbps',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Connection Button
                  GestureDetector(
                    onTap: () async {
                      if (provider.isConnecting) return;

                      if (isConnected) {
                        await provider.disconnect();
                      } else if (provider.selectedConfig != null) {
                        await provider.connectToServer(
                            provider.selectedConfig!, provider.isProxyMode);
                      }
                    },
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF00D4AA).withOpacity(0.3),
                            const Color(0xFF00D4AA).withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D4AA),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            provider.isConnecting
                                ? Icons.hourglass_top
                                : Icons.power_settings_new,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Server Info
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A4A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              'ID',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.selectedConfig?.remark ?? 'Indonesia',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.selectedConfig?.address ??
                                    'IP 256.235.423',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
