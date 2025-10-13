import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildConnectionSettings(),
                      const SizedBox(height: 20),
                      _buildSecuritySettings(),
                      const SizedBox(height: 20),
                      _buildGeneralSettings(),
                      const SizedBox(height: 20),
                      _buildAboutSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
            CupertinoIcons.settings,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          AppLocalizations.of(context).settings,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionSettings() {
    return _buildSection(
      AppLocalizations.of(context).connection,
      CupertinoIcons.wifi,
      [
        Consumer<SettingsService>(
          builder: (context, settingsService, child) {
            return _buildSwitchTile(
              AppLocalizations.of(context).autoConnect,
              AppLocalizations.of(context).autoConnectDescription,
              settingsService.autoConnect,
              (value) => settingsService.setAutoConnect(value),
            );
          },
        ),
        Consumer<SettingsService>(
          builder: (context, settingsService, child) {
            return _buildDropdownTile(
              AppLocalizations.of(context).protocol,
              AppLocalizations.of(context).protocolDescription,
              settingsService.selectedProtocol,
              ['OpenVPN', 'IKEv2', 'WireGuard'],
              (value) => settingsService.setSelectedProtocol(value ?? 'OpenVPN'),
            );
          },
        ),
        _buildActionTile(
          AppLocalizations.of(context).connectionLogs,
          AppLocalizations.of(context).connectionLogsDescription,
          CupertinoIcons.doc_text,
          () => _showConnectionLogs(),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSection(
      AppLocalizations.of(context).security,
      CupertinoIcons.shield,
      [
        Consumer<SettingsService>(
          builder: (context, settingsService, child) {
            return _buildSwitchTile(
              AppLocalizations.of(context).killSwitch,
              AppLocalizations.of(context).killSwitchDescription,
              settingsService.killSwitch,
              (value) => settingsService.setKillSwitch(value),
            );
          },
        ),
        Consumer<SettingsService>(
          builder: (context, settingsService, child) {
            return _buildSwitchTile(
              AppLocalizations.of(context).dnsProtection,
              AppLocalizations.of(context).dnsProtectionDescription,
              settingsService.dnsProtection,
              (value) => settingsService.setDnsProtection(value),
            );
          },
        ),
        _buildActionTile(
          AppLocalizations.of(context).trustedNetworks,
          AppLocalizations.of(context).trustedNetworksDescription,
          CupertinoIcons.house,
          () => _showTrustedNetworks(),
        ),
        _buildActionTile(
          AppLocalizations.of(context).appBypass,
          AppLocalizations.of(context).appBypassDescription,
          CupertinoIcons.square_list,
          () => _showAppBypass(),
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSection(
      AppLocalizations.of(context).general,
      CupertinoIcons.gear,
      [
        Consumer<SettingsService>(
          builder: (context, settingsService, child) {
            return _buildSwitchTile(
              AppLocalizations.of(context).notifications,
              AppLocalizations.of(context).notificationsDescription,
              settingsService.notifications,
              (value) => settingsService.setNotifications(value),
            );
          },
        ),
        Consumer<SettingsService>(
          builder: (context, settingsService, child) {
            String languageDisplay;
            switch (settingsService.selectedLanguage) {
              case 'es':
                languageDisplay = 'Español';
                break;
              case 'de':
                languageDisplay = 'Deutsch';
                break;
              case 'en':
              default:
                languageDisplay = 'English';
                break;
            }
            return _buildDropdownTile(
              AppLocalizations.of(context).language,
              'App interface language',
              languageDisplay,
              ['English', 'Español', 'Deutsch'],
              (value) {
                String languageCode;
                switch (value) {
                  case 'Español':
                    languageCode = 'es';
                    break;
                  case 'Deutsch':
                    languageCode = 'de';
                    break;
                  case 'English':
                  default:
                    languageCode = 'en';
                    break;
                }
                settingsService.setSelectedLanguage(languageCode);
              },
            );
          },
        ),
        _buildActionTile(
          AppLocalizations.of(context).clearCache,
          AppLocalizations.of(context).clearCacheDescription,
          CupertinoIcons.trash,
          () => _clearCache(context),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      AppLocalizations.of(context).about,
      CupertinoIcons.info,
      [
        _buildInfoTile(AppLocalizations.of(context).version, '1.0.0'),
        _buildActionTile(
          AppLocalizations.of(context).privacyPolicy,
          AppLocalizations.of(context).privacyPolicyDescription,
          CupertinoIcons.doc_text,
          () => _showPrivacyPolicy(),
        ),
        _buildActionTile(
          AppLocalizations.of(context).termsOfService,
          AppLocalizations.of(context).termsOfServiceDescription,
          CupertinoIcons.doc_checkmark,
          () => _showTermsOfService(),
        ),
        _buildActionTile(
          AppLocalizations.of(context).helpSupport,
          AppLocalizations.of(context).helpSupportDescription,
          CupertinoIcons.question_circle,
          () => _showSupport(),
        ),
        _buildActionTile(
          AppLocalizations.of(context).rateApp,
          AppLocalizations.of(context).rateAppDescription,
          CupertinoIcons.star,
          () => _rateApp(),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF4FC3F7), size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF4FC3F7),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F3460) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4FC3F7)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                onChanged: onChanged,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
                icon: const Icon(
                  CupertinoIcons.chevron_down,
                  color: Color(0xFF4FC3F7),
                  size: 16,
                ),
                items: options.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              color: const Color(0xFF4FC3F7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionLogs() {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final logs = settingsService.getLastConnections();

    showDialog(
      context: context,
      builder: (context) => _buildConnectionLogsDialog(logs),
    );
  }

  Widget _buildConnectionLogsDialog(List<Map<String, dynamic>> logs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      title: Text(
        'Connection Logs',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: logs.isEmpty
            ? Center(
                child: Text(
                  'No connection logs yet',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final connectTime = DateTime.parse(log['connectTime']);
                  final disconnectTime = log['disconnectTime'] != null
                      ? DateTime.parse(log['disconnectTime'])
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3A3A4E) : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.vpn_lock,
                              color: const Color(0xFF4FC3F7),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log['server'],
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4FC3F7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                log['protocol'],
                                style: const TextStyle(
                                  color: Color(0xFF4FC3F7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Connected: ',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${connectTime.day}/${connectTime.month} ${connectTime.hour.toString().padLeft(2, '0')}:${connectTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (disconnectTime != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Duration: ',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${log['duration']} minutes',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Color(0xFF4FC3F7)),
          ),
        ),
      ],
    );
  }

  void _showTrustedNetworks() {
    _showDialog(
      AppLocalizations.of(context).trustedNetworks,
      AppLocalizations.of(context).trustedNetworksContent,
    );
  }

  void _showAppBypass() {
    _showDialog(
      AppLocalizations.of(context).appBypass,
      AppLocalizations.of(context).appBypassContent,
    );
  }


  void _clearCache(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    try {
      final settingsService = Provider.of<SettingsService>(context, listen: false);
      await settingsService.clearCache();

      if (mounted) {
        _showDialog(
          localizations.clearCache,
          localizations.clearCacheSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        _showDialog(
          'Error',
          localizations.clearCacheError,
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    _showDialog(
      AppLocalizations.of(context).privacyPolicy,
      AppLocalizations.of(context).privacyPolicyContent,
    );
  }

  void _showTermsOfService() {
    _showDialog(
      AppLocalizations.of(context).termsOfService,
      AppLocalizations.of(context).termsOfServiceContent,
    );
  }

  void _showSupport() {
    _showDialog(
      AppLocalizations.of(context).helpSupport,
      AppLocalizations.of(context).helpSupportContent,
    );
  }

  void _rateApp() {
    _showDialog(
      AppLocalizations.of(context).rateApp,
      AppLocalizations.of(context).rateAppContent,
    );
  }

  void _showDialog(String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).ok,
              style: const TextStyle(color: Color(0xFF4FC3F7)),
            ),
          ),
        ],
      ),
    );
  }
}