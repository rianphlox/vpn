// This file contains the implementation of the MainNavigationScreen, which is the main entry point of the app and handles the bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/error_snackbar.dart';
import '../widgets/bottom_navigation.dart';
import 'home_screen.dart';
import 'telegram_proxy_screen.dart';
import 'tools_screen.dart';
import 'store_screen.dart';

/// The main navigation screen of the application.
/// This screen holds the bottom navigation bar and the different screens that can be displayed.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  /// Called when a tab is selected in the bottom navigation bar.
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    // Initialize screens with callback
    _screens = [
      HomeScreen(onTabSelected: _onTabSelected),                // Index 0 - VPN
      StoreScreen(onTabSelected: _onTabSelected),               // Index 1 - Store
      ToolsScreen(onTabSelected: _onTabSelected),               // Index 2 - Tools
      // TelegramProxyScreen(onTabSelected: _onTabSelected),    // Commented out as requested
    ];

    // Auto-update all subscriptions when the app opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<V2RayProvider>(context, listen: false);
      provider.updateAllSubscriptions();
    });
  }

  /// Launches the Telegram URL.
  Future<void> _launchTelegramUrl() async {
    final Uri url = Uri.parse('https://t.me/h3dev');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          TrHelper.errorUrlFormat(context, 'https://t.me/h3dev'),
        );
      }
    }
  }

  /// Shows a dialog with contact information.
  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppTheme.secondaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(TranslationKeys.commonContact),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.telegram,
                    color: Colors.blue,
                    size: 28,
                  ),
                  title: Text(
                    context.tr(TranslationKeys.commonContactOnTelegram),
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchTelegramUrl();
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    context.tr(TranslationKeys.commonCancel),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: Scaffold(
            backgroundColor: const Color(0xFF0F0F23),
            body: Stack(
              children: [
                _screens[_currentIndex],
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: BottomNavigation(
                    currentIndex: _currentIndex,
                    onTabSelected: _onTabSelected,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}