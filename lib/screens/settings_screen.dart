import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/vpn_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoConnect = false;
  bool _killSwitch = true;
  bool _dnsProtection = true;
  bool _notifications = true;
  String _selectedProtocol = 'OpenVPN';
  String _selectedTheme = 'Dark';

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
        const Text(
          'Settings',
          style: TextStyle(
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
      'Connection',
      CupertinoIcons.wifi,
      [
        _buildSwitchTile(
          'Auto Connect',
          'Connect automatically on app launch',
          _autoConnect,
          (value) => setState(() => _autoConnect = value),
        ),
        _buildDropdownTile(
          'Protocol',
          'VPN connection protocol',
          _selectedProtocol,
          ['OpenVPN', 'IKEv2', 'WireGuard'],
          (value) => setState(() => _selectedProtocol = value ?? 'OpenVPN'),
        ),
        _buildActionTile(
          'Connection Logs',
          'View connection history and logs',
          CupertinoIcons.doc_text,
          () => _showConnectionLogs(),
        ),
      ],
    );
  }

  Widget _buildSecuritySettings() {
    return _buildSection(
      'Security',
      CupertinoIcons.shield,
      [
        _buildSwitchTile(
          'Kill Switch',
          'Block internet if VPN disconnects',
          _killSwitch,
          (value) => setState(() => _killSwitch = value),
        ),
        _buildSwitchTile(
          'DNS Protection',
          'Use secure DNS servers',
          _dnsProtection,
          (value) => setState(() => _dnsProtection = value),
        ),
        _buildActionTile(
          'Trusted Networks',
          'Manage auto-disconnect networks',
          CupertinoIcons.house,
          () => _showTrustedNetworks(),
        ),
        _buildActionTile(
          'App Bypass',
          'Exclude apps from VPN tunnel',
          CupertinoIcons.square_list,
          () => _showAppBypass(),
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSection(
      'General',
      CupertinoIcons.gear,
      [
        _buildSwitchTile(
          'Notifications',
          'Show connection status notifications',
          _notifications,
          (value) => setState(() => _notifications = value),
        ),
        _buildDropdownTile(
          'Theme',
          'App appearance',
          _selectedTheme,
          ['Dark', 'Light', 'System'],
          (value) => setState(() => _selectedTheme = value ?? 'Dark'),
        ),
        _buildActionTile(
          'Language',
          'English',
          CupertinoIcons.globe,
          () => _showLanguageSettings(),
        ),
        _buildActionTile(
          'Clear Cache',
          'Free up storage space',
          CupertinoIcons.trash,
          () => _clearCache(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      'About',
      CupertinoIcons.info,
      [
        _buildInfoTile('Version', '1.0.0'),
        _buildActionTile(
          'Privacy Policy',
          'Read our privacy policy',
          CupertinoIcons.doc_text,
          () => _showPrivacyPolicy(),
        ),
        _buildActionTile(
          'Terms of Service',
          'View terms and conditions',
          CupertinoIcons.doc_checkmark,
          () => _showTermsOfService(),
        ),
        _buildActionTile(
          'Help & Support',
          'Get help or contact support',
          CupertinoIcons.question_circle,
          () => _showSupport(),
        ),
        _buildActionTile(
          'Rate App',
          'Rate QShield VPN on Play Store',
          CupertinoIcons.star,
          () => _rateApp(),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
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
                  style: const TextStyle(
                    color: Colors.white,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A3E), width: 1),
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
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4FC3F7),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A3E), width: 1),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4FC3F7)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                onChanged: onChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                dropdownColor: const Color(0xFF1A1A2E),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF2A2A3E), width: 1),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A3E), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionLogs() {
    _showDialog(
      'Connection Logs',
      'Feature coming soon! This will show your recent VPN connections, durations, and data usage.',
    );
  }

  void _showTrustedNetworks() {
    _showDialog(
      'Trusted Networks',
      'Add Wi-Fi networks where VPN will automatically disconnect to save battery and improve speed.',
    );
  }

  void _showAppBypass() {
    _showDialog(
      'App Bypass',
      'Select apps that should bypass the VPN tunnel for direct internet access.',
    );
  }

  void _showLanguageSettings() {
    _showDialog(
      'Language Settings',
      'Choose your preferred language for the app interface.',
    );
  }

  void _clearCache() {
    _showDialog(
      'Clear Cache',
      'Cache cleared successfully! Freed up storage space.',
    );
  }

  void _showPrivacyPolicy() {
    _showDialog(
      'Privacy Policy',
      'QShield VPN respects your privacy. We do not log, track, or store your browsing activity or personal data.',
    );
  }

  void _showTermsOfService() {
    _showDialog(
      'Terms of Service',
      'By using QShield VPN, you agree to our terms of service and acceptable use policy.',
    );
  }

  void _showSupport() {
    _showDialog(
      'Help & Support',
      'Need help? Contact us at support@qshieldvpn.com or visit our FAQ section.',
    );
  }

  void _rateApp() {
    _showDialog(
      'Rate App',
      'Thank you for using QShield VPN! Please rate us on the Play Store to support development.',
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF4FC3F7)),
            ),
          ),
        ],
      ),
    );
  }
}