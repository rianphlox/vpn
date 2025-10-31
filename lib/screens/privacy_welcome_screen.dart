// This file contains the implementation of the PrivacyWelcomeScreen, which is shown to the user on first launch to accept the privacy policy and terms of service.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main_navigation_screen.dart';
import '../utils/app_localizations.dart';

/// A screen that welcomes the user and asks them to accept the privacy policy and terms of service.
class PrivacyWelcomeScreen extends StatefulWidget {
  const PrivacyWelcomeScreen({super.key});

  @override
  State<PrivacyWelcomeScreen> createState() => _PrivacyWelcomeScreenState();
}

class _PrivacyWelcomeScreenState extends State<PrivacyWelcomeScreen> {
  bool _acceptedPrivacy = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Called when the user taps the "Get Started" button.
  /// If the user has not accepted the privacy policy, a snackbar is shown.
  void _acceptAndNavigate() {
    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.privacyWelcomeAcceptPrivacyPolicy),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _savePreferenceAndNavigate();
  }

  /// Saves the user's preference for accepting the privacy policy and navigates to the main screen.
  void _savePreferenceAndNavigate() async {
    if (_acceptedPrivacy) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_accepted', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),

                // QShield branding
                const Text(
                  'QShield',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 80),

                // Shield Icon with animated effect
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.cyan.withOpacity(0.3),
                        Colors.cyan.withOpacity(0.1),
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
                      child: const Icon(
                        Icons.security,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Title and Description
                const Text(
                  'Your Privacy Matters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'We respect your privacy and are committed to\nprotecting your personal data. Please review our\npolicies before continuing.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Privacy acceptance checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: _acceptedPrivacy,
                        onChanged: (value) {
                          setState(() {
                            _acceptedPrivacy = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF00D4AA),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'I accept the ',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          InkWell(
                            onTap: () async {
                              final Uri url = Uri.parse(
                                'https://github.com/code3-dev/ProxyCloud/blob/master/PRIVACY.md',
                              );
                              try {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not open privacy policy'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF00D4AA),
                                decoration: TextDecoration.underline,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Text(
                            ' and ',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          InkWell(
                            onTap: () async {
                              final Uri url = Uri.parse(
                                'https://github.com/code3-dev/ProxyCloud/blob/master/TERMS.md',
                              );
                              try {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Could not open terms of service'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: Color(0xFF00D4AA),
                                decoration: TextDecoration.underline,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: !_acceptedPrivacy ? null : _acceptAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: const Color(0xFF00D4AA).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}