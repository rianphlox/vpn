import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';
import '../providers/language_provider.dart';

class BatterySettingsScreen extends StatefulWidget {
  const BatterySettingsScreen({super.key});

  @override
  State<BatterySettingsScreen> createState() => _BatterySettingsScreenState();
}

class _BatterySettingsScreenState extends State<BatterySettingsScreen> {
  bool _isLoading = false;

  Future<void> _openBatteryOptimizationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const platform = MethodChannel('com.cloud.pira/settings');
      await platform.invokeMethod('openBatteryOptimizationSettings');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.batterySettingsBatteryOptimizationOpened,
              ),
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.batterySettingsErrorOpening,
                parameters: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openGeneralBatterySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const platform = MethodChannel('com.cloud.pira/settings');
      await platform.invokeMethod('openGeneralBatterySettings');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.batterySettingsGeneralBatteryOpened),
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.batterySettingsErrorOpening,
                parameters: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAppSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      const platform = MethodChannel('com.cloud.pira/settings');
      await platform.invokeMethod('openAppSettings');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.batterySettingsAppSettingsOpened),
            ),
            backgroundColor: AppTheme.primaryBlue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                TranslationKeys.batterySettingsErrorOpening,
                parameters: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: _buildBatterySettingsScreen(context),
        );
      },
    );
  }

  Widget _buildBatterySettingsScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.batterySettingsTitle)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.connectedGreen.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.battery_charging_full,
                    size: 48,
                    color: AppTheme.connectedGreen,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(TranslationKeys.batterySettingsHeaderTitle),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      TranslationKeys.batterySettingsHeaderDescription,
                    ),
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Battery Optimization Section
            _buildSectionCard(
              context,
              title: context.tr(
                TranslationKeys.batterySettingsBatteryOptimization,
              ),
              description: context.tr(
                TranslationKeys.batterySettingsBatteryOptimizationDesc,
              ),
              icon: Icons.battery_saver,
              buttonText: context.tr(
                TranslationKeys.batterySettingsOpenBatteryOptimization,
              ),
              onPressed: _isLoading ? null : _openBatteryOptimizationSettings,
            ),

            const SizedBox(height: 16),

            // General Battery Settings Section
            _buildSectionCard(
              context,
              title: context.tr(TranslationKeys.batterySettingsGeneralBattery),
              description: context.tr(
                TranslationKeys.batterySettingsGeneralBatteryDesc,
              ),
              icon: Icons.settings_power,
              buttonText: context.tr(
                TranslationKeys.batterySettingsOpenBatterySettings,
              ),
              onPressed: _isLoading ? null : _openGeneralBatterySettings,
            ),

            const SizedBox(height: 16),

            // App Settings Section
            _buildSectionCard(
              context,
              title: context.tr(TranslationKeys.batterySettingsAppSettings),
              description: context.tr(
                TranslationKeys.batterySettingsAppSettingsDesc,
              ),
              icon: Icons.app_settings_alt,
              buttonText: context.tr(
                TranslationKeys.batterySettingsOpenAppSettings,
              ),
              onPressed: _isLoading ? null : _openAppSettings,
            ),

            const SizedBox(height: 24),

            // Information Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        context.tr(TranslationKeys.batterySettingsWhyDisable),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(TranslationKeys.batterySettingsBenefitsList),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Warning Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr(
                          TranslationKeys.batterySettingsImportantNote,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr(TranslationKeys.batterySettingsDeviceNote),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required VoidCallback? onPressed,
  }) {
    return Card(
      color: AppTheme.cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.open_in_new, size: 18),
                label: Text(
                  _isLoading
                      ? context.tr(TranslationKeys.batterySettingsOpening)
                      : buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
