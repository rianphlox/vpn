// This file contains the implementation of the ServerBottomSheet widget, which is a bottom sheet that allows the user to select a V2Ray server.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/v2ray_config.dart';
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import '../services/v2ray_service.dart';
import '../theme/app_theme.dart';

/// A bottom sheet that allows the user to select a V2Ray server.
class ServerBottomSheet extends StatefulWidget {
  /// The list of available V2Ray configurations.
  final List<V2RayConfig> configs;

  /// The currently selected V2Ray configuration.
  final V2RayConfig? selectedConfig;

  /// Whether the app is currently connecting to a server.
  final bool isConnecting;

  /// A callback function that is called when a configuration is selected.
  final Future<void> Function(V2RayConfig) onConfigSelected;

  /// Creates a new instance of the [ServerBottomSheet].
  const ServerBottomSheet({
    Key? key,
    required this.configs,
    required this.selectedConfig,
    required this.isConnecting,
    required this.onConfigSelected,
  }) : super(key: key);

  @override
  State<ServerBottomSheet> createState() => _ServerBottomSheetState();
}

class _ServerBottomSheetState extends State<ServerBottomSheet> {
  final Map<String, int?> _pings = {};
  final Map<String, bool> _loadingPings = {};
  final V2RayService _v2rayService = V2RayService();

  @override
  void initState() {
    super.initState();
    _loadAllPings();
  }

  /// Loads the pings for all V2Ray configurations.
  Future<void> _loadAllPings() async {
    for (final config in widget.configs) {
      _loadPingForConfig(config);
    }
  }

  /// Loads the ping for a single V2Ray configuration.
  Future<void> _loadPingForConfig(V2RayConfig config) async {
    if (mounted) {
      setState(() {
        _loadingPings[config.id] = true;
      });
    }

    try {
      final delay = await _v2rayService.getServerDelay(config);
      if (mounted) {
        setState(() {
          _pings[config.id] = delay;
          _loadingPings[config.id] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pings[config.id] = null;
          _loadingPings[config.id] = false;
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
          child: _buildBottomSheet(context),
        );
      },
    );
  }

  /// Builds the bottom sheet widget.
  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr(TranslationKeys.serverBottomSheetSelectServer),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Close button only
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Server list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.configs.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final config = widget.configs[index];
                final isSelected = widget.selectedConfig?.id == config.id;
                final isLoadingPing = _loadingPings[config.id] ?? false;
                final ping = _pings[config.id];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? AppTheme.connectedGreen.withOpacity(0.1)
                      : null,
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppTheme.connectedGreen
                          : AppTheme.textGrey,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          config.remark,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isLoadingPing)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      else if (ping != null)
                        Text(
                          '${ping}ms',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${config.address}:${config.port} (${config.configType})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${context.tr(TranslationKeys.serverBottomSheetStatus)}: ${config.isConnected ? context.tr(TranslationKeys.serverBottomSheetConnected) : context.tr(TranslationKeys.serverBottomSheetDisconnected)}',
                        style: TextStyle(
                          color: config.isConnected ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  onTap: widget.isConnecting
                      ? null
                      : () async {
                          // Get the provider to check connection status
                          final provider = Provider.of<V2RayProvider>(
                            context,
                            listen: false,
                          );

                          // Check if already connected to VPN
                          if (provider.activeConfig != null) {
                            // Show popup to inform user to disconnect first
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  context.tr(
                                    TranslationKeys
                                        .serverBottomSheetConnectionActive,
                                  ),
                                ),
                                content: Text(
                                  context.tr(
                                    TranslationKeys
                                        .serverBottomSheetDisconnectFirst,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      context.tr(TranslationKeys.commonOk),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Not connected, proceed with selection
                            await widget.onConfigSelected(config);
                            Navigator.pop(context);
                          }
                        },
                  // Removed onLongPress handler for server pinging as requested
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Function to show the bottom sheet
void showServerSelector({
  required BuildContext context,
  required List<V2RayConfig> configs,
  required V2RayConfig? selectedConfig,
  required bool isConnecting,
  required Future<void> Function(V2RayConfig) onConfigSelected,
}) {
  // Get the provider to check connection status
  final provider = Provider.of<V2RayProvider>(context, listen: false);

  // Check if already connected to VPN
  if (provider.activeConfig != null) {
    // Show popup to inform user to disconnect first
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tr(TranslationKeys.serverBottomSheetConnectionActive),
        ),
        content: Text(
          context.tr(TranslationKeys.serverBottomSheetDisconnectFirst),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr(TranslationKeys.commonOk)),
          ),
        ],
      ),
    );
    return; // Don't show the bottom sheet
  }

  // Not connected, show server selector
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => ServerBottomSheet(
        configs: configs,
        selectedConfig: selectedConfig,
        isConnecting: isConnecting,
        onConfigSelected: onConfigSelected,
      ),
    ),
  );
}