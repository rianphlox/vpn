import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import 'about_screen.dart';
import 'subscription_management_screen.dart';
import 'server_selection_screen.dart';
import 'connection_details_screen.dart';
import 'tools_screen.dart';

/// The main screen of the application.
class HomeScreen extends StatefulWidget {
  /// A callback function that is called when a tab is selected.
  final Function(int)? onTabSelected;

  /// Creates a new instance of the [HomeScreen].
  const HomeScreen({super.key, this.onTabSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _urlController.text = ''; // Default to empty subscription URL

    // Check if user has configs to determine if we should show onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<V2RayProvider>(context, listen: false);
      if (provider.configs.isNotEmpty) {
        setState(() {
          _showOnboarding = false;
        });
      }
    });

    // Listen for connection state changes
    final v2rayProvider = Provider.of<V2RayProvider>(context, listen: false);
    v2rayProvider.addListener(_onProviderChanged);
  }

  /// Called when the V2RayProvider changes.
  void _onProviderChanged() {
    // Update onboarding state based on configs
    final provider = Provider.of<V2RayProvider>(context, listen: false);
    if (mounted && provider.configs.isNotEmpty && _showOnboarding) {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: Scaffold(
            backgroundColor: const Color(0xFF0F0F23),
            body: _showOnboarding ? _buildOnboardingScreen() : _buildMainScreen(),
          ),
        );
      },
    );
  }

  /// Builds the onboarding screen, which is shown to new users.
  Widget _buildOnboardingScreen() {
    return Container(
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
              // App Title
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
                'Protect Every Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your data stays yours. Stay private and secure on\nevery network.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionManagementScreen(),
                      ),
                    );
                    // Check if configs were added and update onboarding state
                    if (mounted) {
                      final provider = Provider.of<V2RayProvider>(context, listen: false);
                      if (provider.configs.isNotEmpty) {
                        setState(() {
                          _showOnboarding = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    foregroundColor: Colors.white,
                    elevation: 0,
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
    );
  }

  /// Builds the main screen, which is shown after the user has added a configuration.
  Widget _buildMainScreen() {
    return Container(
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
        child: Consumer<V2RayProvider>(
          builder: (context, provider, _) {
            final isConnected = provider.activeConfig != null;
            final selectedConfig = provider.selectedConfig;

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QShield',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          showServerSelectionScreen(
                            context: context,
                            configs: provider.configs,
                            selectedConfig: provider.selectedConfig,
                            isConnecting: provider.isConnecting,
                            onConfigSelected: (config) async {
                              await provider.selectConfig(config);
                              await provider.connectToServer(config, provider.isProxyMode);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Connection Timer
                GestureDetector(
                  onTap: isConnected ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConnectionDetailsScreen(),
                      ),
                    );
                  } : null,
                  child: StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      return Text(
                        isConnected ? provider.v2rayService.getFormattedConnectedTime() : '00:00:00',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Connection Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 16,
                        color: isConnected ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
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
                    } else if (selectedConfig != null) {
                      await provider.connectToServer(selectedConfig, provider.isProxyMode);
                    } else if (provider.configs.isNotEmpty) {
                      await provider.selectConfig(provider.configs.first);
                      await provider.connectToServer(provider.configs.first, provider.isProxyMode);
                    }
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isConnected ? Colors.green : Colors.cyan).withValues(alpha: 0.3),
                          (isConnected ? Colors.green : Colors.cyan).withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.green : const Color(0xFF00D4AA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          provider.isConnecting ? Icons.hourglass_top : Icons.power_settings_new,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Tap to Connect
                Text(
                  isConnected ? 'Tap to Disconnect' : 'Tap to Connect',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Mode buttons and Server selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Mode Selection
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A4A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Smart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A4A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Global',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Server Selection
                      GestureDetector(
                        onTap: () {
                          showServerSelectionScreen(
                            context: context,
                            configs: provider.configs,
                            selectedConfig: provider.selectedConfig,
                            isConnecting: provider.isConnecting,
                            onConfigSelected: (config) async {
                              await provider.selectConfig(config);
                            },
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A4A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'FI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        selectedConfig?.remark ?? 'Finland',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        selectedConfig?.address ?? 'Helsinki',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text(
                                  '65ms',
                                  style: TextStyle(
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            );
          },
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