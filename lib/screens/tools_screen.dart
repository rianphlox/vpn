// This file contains the implementation of the ToolsScreen, which provides a list of tools and settings for the user.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';
import '../providers/language_provider.dart';
import 'ip_info_screen.dart';
import 'host_checker_screen.dart';
import 'speedtest_screen.dart';
import 'subscription_management_screen.dart';
import 'vpn_settings_screen.dart';
import 'blocked_apps_screen.dart';
import 'per_app_tunnel_screen.dart';
import 'backup_restore_screen.dart';
import 'wallpaper_settings_screen.dart';
import 'wallpaper_store_screen.dart';
import 'battery_settings_screen.dart';
import 'language_settings_screen.dart';

/// A screen that displays a list of tools and settings.
class ToolsScreen extends StatefulWidget {
  /// A callback function that is called when a tab is selected.
  final Function(int)? onTabSelected;

  /// Creates a new instance of the [ToolsScreen].
  const ToolsScreen({super.key, this.onTabSelected});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: Scaffold(
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
                          const Text(
                            'Tools',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tools Grid
                    Expanded(
                      child: GridView.count(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          // Language option commented out as requested
                          // _buildModernToolCard(
                          //   title: 'Language',
                          //   description: 'Change app language',
                          //   icon: Icons.language,
                          //   color: Colors.blue,
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => const LanguageSettingsScreen(),
                          //       ),
                          //     );
                          //   },
                          // ),
                          _buildModernToolCard(
                            title: 'Subscriptions',
                            description: 'Manage your subscriptions',
                            icon: Icons.subscriptions,
                            color: Colors.purple,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SubscriptionManagementScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModernToolCard(
                            title: 'IP Info',
                            description: 'Check your IP information',
                            icon: Icons.public,
                            color: Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const IpInfoScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModernToolCard(
                            title: 'Blocked Apps',
                            description: 'Manage blocked applications',
                            icon: Icons.block,
                            color: Colors.grey,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BlockedAppsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModernToolCard(
                            title: 'Per-App Tunnel',
                            description: 'Configure app-specific routing',
                            icon: Icons.shield_moon,
                            color: const Color(0xFF00D4AA),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PerAppTunnelScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModernToolCard(
                            title: 'Battery',
                            description: 'Background battery optimization',
                            icon: Icons.battery_charging_full,
                            color: Colors.yellow,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BatterySettingsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModernToolCard(
                            title: 'Backup',
                            description: 'Backup and restore settings',
                            icon: Icons.backup,
                            color: Colors.teal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BackupRestoreScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a modern card widget for a tool item.
  Widget _buildModernToolCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A4A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}