// This file contains a backup of the server selection screen. It is not currently used in the app.

import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proxycloud/models/v2ray_config.dart';
import 'package:proxycloud/models/subscription.dart';
import 'package:proxycloud/providers/v2ray_provider.dart';
import 'package:proxycloud/services/v2ray_service.dart';
import 'package:proxycloud/theme/app_theme.dart';
import 'package:proxycloud/utils/app_localizations.dart';

/// A screen that allows the user to select a V2Ray server to connect to.
class ServerSelectionScreen extends StatefulWidget {
  /// The list of available V2Ray configurations.
  final List<V2RayConfig> configs;

  /// The currently selected V2Ray configuration.
  final V2RayConfig? selectedConfig;

  /// Whether the app is currently connecting to a server.
  final bool isConnecting;

  /// A callback function that is called when a configuration is selected.
  final Future<void> Function(V2RayConfig) onConfigSelected;

  /// Creates a new instance of the [ServerSelectionScreen].
  const ServerSelectionScreen({
    Key? key,
    required this.configs,
    required this.selectedConfig,
    required this.isConnecting,
    required this.onConfigSelected,
  }) : super(key: key);

  @override
  State<ServerSelectionScreen> createState() => _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends State<ServerSelectionScreen> {
  String _selectedFilter = 'All';
  final Map<String, int?> _pings = {};
  final Map<String, bool> _loadingPings = {};
  final V2RayService _v2rayService = V2RayService();
  final StreamController<String> _autoConnectStatusStream =
      StreamController<String>.broadcast();

  /// Imports a V2Ray configuration from the clipboard.
  Future<void> _importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionClipboardEmpty),
            ),
          ),
        );
        return;
      }

      final provider = Provider.of<V2RayProvider>(context, listen: false);
      final config = await provider.importConfigFromText(clipboardData.text!);

      if (config != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionImportSuccess),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionImportFailed),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.serverSelectionImportFailed),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Imports multiple V2Ray configurations from the clipboard.
  Future<void> _importMultipleFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null ||
          clipboardData.text == null ||
          clipboardData.text!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionClipboardEmpty),
            ),
          ),
        );
        return;
      }

      final provider = Provider.of<V2RayProvider>(context, listen: false);
      final configs = await provider.importConfigsFromText(clipboardData.text!);

      if (configs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${configs.length} ${context.tr(TranslationKeys.serverSelectionImportSuccess)}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(TranslationKeys.serverSelectionImportFailed),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.serverSelectionImportFailed),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Deletes a local V2Ray configuration.
  Future<void> _deleteLocalConfig(V2RayConfig config) async {
    try {
      await Provider.of<V2RayProvider>(
        context,
        listen: false,
      ).removeConfig(config);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.serverSelectionDeleteSuccess),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              TranslationKeys.serverSelectionDeleteFailed,
              parameters: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  final Map<String, bool> _cancelPingTasks = {};
  Timer? _batchTimeoutTimer;
  bool _sortByPing = false; // New variable for ping sorting
  bool _sortAscending = true; // New variable for sort direction
  bool _isPingingServers = false; // New variable for ping loading state

  @override
  void initState() {
    super.initState();
    _selectedFilter = 'All';
  }

  @override
  void dispose() {
    _autoConnectStatusStream.close();
    _batchTimeoutTimer?.cancel();
    _cancelAllPingTasks();
    super.dispose();
  }

  /// Groups V2Ray configurations by host.
  Map<String, List<V2RayConfig>> _groupConfigsByHost(
    List<V2RayConfig> configs,
  ) {
    final Map<String, List<V2RayConfig>> groupedConfigs = {};
    for (var config in configs) {
      // Use config.id as the key to ensure each config is treated individually
      final key = config.id;
      if (!groupedConfigs.containsKey(key)) {
        groupedConfigs[key] = [];
      }
      groupedConfigs[key]!.add(config);
    }
    return groupedConfigs;
  }

  /// Loads the pings for all V2Ray configurations.
  Future<void> _loadAllPings() async {
    final provider = Provider.of<V2RayProvider>(context, listen: false);
    final configs = provider.configs;
    final groupedConfigs = _groupConfigsByHost(configs);
    for (var host in groupedConfigs.keys) {
      if (!mounted) return;
      final configsForHost = groupedConfigs[host]!;
      final representativeConfig = configsForHost.first;
      await _loadPingForConfig(representativeConfig, configsForHost);
    }
  }

  /// Loads the ping for a single V2Ray configuration.
  Future<void> _loadPingForConfig(
    V2RayConfig config,
    List<V2RayConfig> relatedConfigs,
  ) async {
    // Check if task was cancelled before starting
    if (_cancelPingTasks[config.id] == true || !mounted) return;

    try {
      // Safely update loading state
      if (mounted) {
        setState(() {
          for (var relatedConfig in relatedConfigs) {
            _loadingPings[relatedConfig.id] = true;
          }
        });
      }

      // Add timeout to prevent hanging with proper error handling
      int? ping;
      try {
        ping = await _v2rayService
            .getServerDelay(config)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                debugPrint('Ping timeout for server ${config.remark}');
                return -1; // Return -1 on timeout
              },
            );
      } catch (e) {
        debugPrint('Error pinging server ${config.remark}: $e');
        ping = -1; // Return -1 on error
      }

      // Check if widget is still mounted and task wasn't cancelled
      if (mounted && _cancelPingTasks[config.id] != true) {
        setState(() {
          for (var relatedConfig in relatedConfigs) {
            _pings[relatedConfig.id] = ping;
            _loadingPings[relatedConfig.id] = false;
          }
        });
      }
    } catch (e) {
      debugPrint(
        'Unexpected error in _loadPingForConfig for ${config.remark}: $e',
      );
      // Safely handle error state
      if (mounted && _cancelPingTasks[config.id] != true) {
        setState(() {
          for (var relatedConfig in relatedConfigs) {
            _pings[relatedConfig.id] = -1; // Set -1 for failed pings
            _loadingPings[relatedConfig.id] = false;
          }
        });
      }
    }
  }

  /// Pings a V2Ray server and returns the delay in milliseconds.
  Future<int?> _pingServer(V2RayConfig config) async {
    try {
      // Check if task was cancelled or widget unmounted
      if (_cancelPingTasks[config.id] == true || !mounted) {
        return -1;
      }

      return await _v2rayService
          .getServerDelay(config)
          .timeout(
            const Duration(seconds: 8), // Reduced timeout for better UX
            onTimeout: () {
              debugPrint('Ping timeout for server ${config.remark}');
              return -1; // Return -1 on timeout
            },
          );
    } catch (e) {
      debugPrint('Error pinging server ${config.remark}: $e');
      return -1; // Return -1 on error
    }
  }

  /// Runs the auto-connect algorithm to find the fastest server.
  Future<void> _runAutoConnectAlgorithm(
    List<V2RayConfig> configs,
    BuildContext context,
  ) async {
    // Clear any existing ping tasks
    _cancelPingTasks.clear();
    V2RayConfig? selectedConfig;
    final remainingConfigs = List<V2RayConfig>.from(configs);

    // Check if widget is still mounted before starting
    if (!mounted) return;

    try {
      while (remainingConfigs.isNotEmpty && selectedConfig == null && mounted) {
        final batchSize = min(3, remainingConfigs.length); // Reduced batch size
        final currentBatch = remainingConfigs.take(batchSize).toList();
        remainingConfigs.removeRange(0, batchSize);

        // Check mounted state before updating stream
        if (!mounted) break;

        try {
          _autoConnectStatusStream.add(
            context.tr(
              TranslationKeys.serverSelectionTestingBatch,
              parameters: {'count': currentBatch.length.toString()},
            ),
          );
        } catch (e) {
          debugPrint('Error updating status stream: $e');
        }

        final completer = Completer<V2RayConfig?>();

        // Create a timeout with proper cleanup
        _batchTimeoutTimer?.cancel();
        _batchTimeoutTimer = Timer(const Duration(seconds: 8), () {
          if (!completer.isCompleted && mounted) {
            debugPrint('Batch timeout reached, moving to next batch');
            try {
              _autoConnectStatusStream.add(
                context.tr(TranslationKeys.serverSelectionBatchTimeout),
              );
            } catch (e) {
              debugPrint('Error updating status stream on timeout: $e');
            }
            completer.complete(null);
          }
        });

        try {
          // Start ping tasks for current batch
          final pingFutures = currentBatch.map(
            (config) => _processPingTask(config, completer),
          );
          await Future.wait(pingFutures, eagerError: false);

          // Wait for completer to complete or timeout
          selectedConfig = await completer.future.timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint('Completer timeout reached');
              return null;
            },
          );

          _batchTimeoutTimer?.cancel();
        } catch (e) {
          if (e.toString().contains('timeout')) {
            debugPrint('Timeout in batch processing: $e');
          } else {
            debugPrint('Error in batch processing: $e');
          }
          _batchTimeoutTimer?.cancel();
          continue;
        }
      }

      // Clean up timer
      _batchTimeoutTimer?.cancel();
      _batchTimeoutTimer = null;

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

      if (selectedConfig != null) {
        try {
          if (mounted) {
            _autoConnectStatusStream.add(
              context.tr(
                TranslationKeys.serverSelectionFastestConnection,
                parameters: {
                  'server': selectedConfig.remark,
                  'ping': _pings[selectedConfig.id].toString(),
                },
              ),
            );
          }

          // Attempt to connect to the selected server
          await widget.onConfigSelected(selectedConfig);

          // Safe navigation with proper checks
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close auto-connect dialog
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close server selection screen
            }
          }
        } catch (e) {
          debugPrint('Error connecting to selected server: $e');
          if (mounted) {
            try {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(); // Close auto-connect dialog
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(
                      TranslationKeys.serverSelectionConnectFailed,
                      parameters: {
                        'server': selectedConfig.remark,
                        'error': e.toString(),
                      },
                    ),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            } catch (navError) {
              debugPrint('Error with navigation/snackbar: $navError');
            }
          }
        }
      } else {
        // No suitable server found
        if (mounted) {
          try {
            _autoConnectStatusStream.add(
              context.tr(TranslationKeys.serverSelectionNoSuitableServer),
            );

            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Close auto-connect dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr(TranslationKeys.serverSelectionNoSuitableServer),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error showing no server found message: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in auto connect algorithm: $e');

      // Safe error handling with navigation
      if (mounted) {
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close auto-connect dialog
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr(
                  TranslationKeys.serverSelectionErrorUpdating,
                  parameters: {'error': e.toString()},
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        } catch (navError) {
          debugPrint('Error with navigation/snackbar in catch: $navError');
        }
      }
    } finally {
      // Ensure cleanup happens even if errors occur
      try {
        _batchTimeoutTimer?.cancel();
        _batchTimeoutTimer = null;
        _cancelAllPingTasks();
      } catch (e) {
        debugPrint('Error during cleanup: $e');
      }
    }
  }

  /// Processes a ping task for a single V2Ray configuration.
  Future<void> _processPingTask(
    V2RayConfig config,
    Completer<V2RayConfig?> completer,
  ) async {
    // Early return if widget unmounted or completer already completed
    if (!mounted ||
        completer.isCompleted ||
        _cancelPingTasks[config.id] == true) {
      return;
    }

    try {
      // Safely update status stream
      if (mounted && !completer.isCompleted) {
        try {
          _autoConnectStatusStream.add(
            context.tr(
              TranslationKeys.serverSelectionTestingServer,
              parameters: {'server': config.remark},
            ),
          );
        } catch (e) {
          debugPrint('Error updating status stream: $e');
        }
      }

      // Ping the server with timeout
      int? ping;
      try {
        ping = await _pingServer(config).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('Ping task timeout for server ${config.remark}');
            return -1; // Return -1 on timeout
          },
        );
      } catch (e) {
        if (e.toString().contains('timeout')) {
          debugPrint('Timeout in ping task for ${config.remark}: $e');
        } else {
          debugPrint('Error pinging server in task ${config.remark}: $e');
        }
        ping = -1; // Return -1 on error
      }

      // Check if we should continue (widget still mounted and completer not completed)
      if (!mounted ||
          completer.isCompleted ||
          _cancelPingTasks[config.id] == true) {
        return;
      }

      // Safely update state
      try {
        if (mounted) {
          setState(() {
            _pings[config.id] = ping;
            _loadingPings[config.id] = false;
          });
        }
      } catch (e) {
        debugPrint('Error updating ping state for ${config.remark}: $e');
      }

      // Check if we found a valid server
      if (ping != null && ping > 0 && ping < 5000) {
        // Valid ping range
        if (mounted && !completer.isCompleted) {
          try {
            _autoConnectStatusStream.add(
              context.tr(
                TranslationKeys.serverSelectionLowestPing,
                parameters: {'server': config.remark, 'ping': ping.toString()},
              ),
            );
            _cancelAllPingTasks();
            completer.complete(config);
          } catch (e) {
            debugPrint(
              'Error completing successful ping for ${config.remark}: $e',
            );
          }
        }
      } else {
        // Server failed or had invalid ping
        if (mounted && !completer.isCompleted) {
          try {
            _autoConnectStatusStream.add(
              context.tr(
                TranslationKeys.serverSelectionTimeout,
                parameters: {'server': config.remark},
              ),
            );
          } catch (e) {
            debugPrint('Error updating failed status for ${config.remark}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Unexpected error in _processPingTask for ${config.remark}: $e',
      );

      // Safely update loading state on error
      try {
        if (mounted && !completer.isCompleted) {
          setState(() {
            _pings[config.id] = -1; // Set -1 for failed pings
            _loadingPings[config.id] = false;
          });
        }
      } catch (stateError) {
        debugPrint(
          'Error updating error state for ${config.remark}: $stateError',
        );
      }
    }
  }

  /// Cancels all ongoing ping tasks.
  void _cancelAllPingTasks() {
    _cancelPingTasks.updateAll((key, value) => true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<V2RayProvider>(context, listen: true);
    final subscriptions = provider.subscriptions;
    final configs = provider.configs;

    final filterOptions = [
      'All',
      'Local',
      ...subscriptions.map((sub) => sub.name),
    ];

    // Add sort and ping buttons in the app bar actions
    final List<Widget> appBarActions = [
      // Ping button
      IconButton(
        icon: _isPingingServers
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryGreen,
                  ),
                ),
              )
            : const Icon(Icons.network_check),
        tooltip: context.tr(TranslationKeys.serverSelectionTestPing),
        onPressed: _isPingingServers
            ? null
            : () async {
                // Prevent multiple ping operations at once
                if (_isPingingServers) return;

                try {
                  if (mounted) {
                    setState(() {
                      _isPingingServers = true;
                      // Clear existing pings when starting new test
                      _pings.clear();
                      _loadingPings.clear();
                    });
                  }

                  if (_selectedFilter == 'All') {
                    await _loadAllPings();
                  } else if (_selectedFilter == 'Local') {
                    // Get local configs (not in any subscription)
                    final allSubscriptionConfigIds = subscriptions
                        .expand((sub) => sub.configIds)
                        .toSet();
                    final provider = Provider.of<V2RayProvider>(
                      context,
                      listen: false,
                    );
                    final allConfigs = provider.configs;
                    final localConfigs = allConfigs
                        .where(
                          (config) =>
                              !allSubscriptionConfigIds.contains(config.id),
                        )
                        .toList();

                    // Test pings for local configs with error handling
                    for (var config in localConfigs) {
                      if (!mounted) break;
                      try {
                        await _loadPingForConfig(config, [config]);
                      } catch (e) {
                        debugPrint(
                          'Error pinging local config ${config.remark}: $e',
                        );
                        // Continue with next config instead of crashing
                      }
                    }
                  } else {
                    try {
                      final subscription = subscriptions.firstWhere(
                        (sub) => sub.name == _selectedFilter,
                        orElse: () => Subscription(
                          id: '',
                          name: '',
                          url: '',
                          lastUpdated: DateTime.now(),
                          configIds: [],
                        ),
                      );
                      final provider = Provider.of<V2RayProvider>(
                        context,
                        listen: false,
                      );
                      final allConfigs = provider.configs;
                      final configsToTest = allConfigs
                          .where(
                            (config) =>
                                subscription.configIds.contains(config.id),
                          )
                          .toList();

                      // Test pings for subscription configs with error handling
                      for (var config in configsToTest) {
                        if (!mounted) break;
                        try {
                          await _loadPingForConfig(config, [config]);
                        } catch (e) {
                          debugPrint(
                            'Error pinging subscription config ${config.remark}: $e',
                          );
                          // Continue with next config instead of crashing
                        }
                      }
                    } catch (e) {
                      debugPrint('Error processing subscription filter: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error testing servers: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('Error in ping operation: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error testing servers: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isPingingServers = false;
                    });
                  }
                }
              },
      ),
      // Sort button
      IconButton(
        icon: Icon(
          _sortByPing ? Icons.sort : Icons.sort_outlined,
          color: _sortByPing ? AppTheme.primaryGreen : null,
        ),
        tooltip: context.tr(TranslationKeys.serverSelectionSortByPing),
        onPressed: () {
          setState(() {
            if (_sortByPing) {
              _sortAscending = !_sortAscending;
            } else {
              _sortByPing = true;
              _sortAscending = true;
            }
          });
        },
      ),
    ];

    List<V2RayConfig> filteredConfigs = [];
    if (_selectedFilter == 'All') {
      filteredConfigs = List.from(configs);
    } else if (_selectedFilter == 'Local') {
      // Filter configs that don't belong to any subscription
      final allSubscriptionConfigIds = subscriptions
          .expand((sub) => sub.configIds)
          .toSet();
      filteredConfigs = configs
          .where((config) => !allSubscriptionConfigIds.contains(config.id))
          .toList();
    } else {
      final subscription = subscriptions.firstWhere(
        (sub) => sub.name == _selectedFilter,
        orElse: () => Subscription(
          id: '',
          name: '',
          url: '',
          lastUpdated: DateTime.now(),
          configIds: [],
        ),
      );
      filteredConfigs = configs
          .where((config) => subscription.configIds.contains(config.id))
          .toList();
    }

    // Sort configs by ping if enabled
    if (_sortByPing) {
      filteredConfigs.sort((a, b) {
        final pingA = _pings[a.id];
        final pingB = _pings[b.id];

        // Check if ping values are valid (not null, -1, or 0)
        final isValidPingA = pingA != null && pingA > 0;
        final isValidPingB = pingB != null && pingB > 0;

        // Handle invalid pings - put them at the bottom
        if (!isValidPingA && !isValidPingB) {
          // Both invalid, but prioritize -1 (timeout) over null (no test)
          if (pingA == -1 && pingB == -1) return 0;
          if (pingA == -1 && pingB == null) return -1;
          if (pingA == null && pingB == -1) return 1;
          return 0;
        }
        if (!isValidPingA) return 1; // Invalid pings go to bottom
        if (!isValidPingB) return -1; // Valid pings stay on top

        // Sort by ping value (only valid pings reach here)
        return _sortAscending ? pingA.compareTo(pingB) : pingB.compareTo(pingA);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      floatingActionButton: _selectedFilter == 'Local'
          ? FloatingActionButton(
              onPressed: _importMultipleFromClipboard,
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.paste),
            )
          : null,
      appBar: AppBar(
        title: const Text(
          'Location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0F0F23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          ...appBarActions,
          if (_selectedFilter != 'Local')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          TranslationKeys.serverSelectionUpdatingServers,
                        ),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );

                  if (_selectedFilter == 'All') {
                    await provider.updateAllSubscriptions();
                  } else if (_selectedFilter != 'Default') {
                    final subscription = subscriptions.firstWhere(
                      (sub) => sub.name == _selectedFilter,
                      orElse: () => Subscription(
                        id: '',
                        name: '',
                        url: '',
                        lastUpdated: DateTime.now(),
                        configIds: [],
                      ),
                    );
                    if (subscription.id.isNotEmpty) {
                      await provider.updateSubscription(subscription);
                    }
                  }

                  setState(() {});
                  await _loadAllPings();

                  if (provider.errorMessage.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(provider.errorMessage),
                        backgroundColor: Colors.red.shade700,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    provider.clearError();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr(
                            TranslationKeys.serverSelectionServersUpdated,
                          ),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          TranslationKeys.serverSelectionErrorUpdating,
                          parameters: {'error': e.toString()},
                        ),
                      ),
                    ),
                  );
                }
              },
              tooltip: context.tr(TranslationKeys.serverSelectionUpdateServers),
            ),
        ],
      ),
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
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A4A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search location or server..',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Popular Servers Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Servers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Popular Servers List
            SizedBox(
              height: 200,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final countries = ['Indonesia', 'Singapore', 'United States', 'Germany'];
                  final cities = ['Jakarta', 'Marina Bay', 'Los Angeles', 'Frankfurt'];
                  final flags = ['🇮🇩', '🇸🇬', '🇺🇸', '🇩🇪'];
                  final pings = ['43 ms', '28 ms', '76 ms', '110 ms'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A4A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          flags[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                countries[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                cities[index],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          pings[index],
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 16,
                          height: 12,
                          child: CustomPaint(
                            painter: SignalBarsPainter(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // All Servers Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Servers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // All Servers List
            Expanded(
              child: filteredConfigs.isEmpty
                  ? const Center(
                      child: Text(
                        'No servers available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredConfigs.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        final config = filteredConfigs[index];
                        final isSelected = provider.selectedConfig?.id == config.id;

                        // Get country from config name or use default
                        String countryName = config.remark.contains('🇭🇰') ? 'Hongkong' :
                                            config.remark.contains('🇺🇸') ? 'United States' :
                                            config.remark.contains('🇳🇱') ? 'Netherlands' :
                                            config.remark;
                        String locationName = config.address;
                        String flag = config.remark.contains('🇭🇰') ? '🇭🇰' :
                                     config.remark.contains('🇺🇸') ? '🇺🇸' :
                                     config.remark.contains('🇳🇱') ? '🇳🇱' : '🌍';
                        String ping = _pings[config.id] != null && _pings[config.id]! > 0 ?
                                     '${_pings[config.id]}ms' : '-- ms';

                        // Determine if it should show green dot
                        bool showGreenDot = config.remark.contains('Los Angeles');

                        return GestureDetector(
                          onTap: () async {
                            if (widget.isConnecting) return;

                            try {
                              await widget.onConfigSelected(config);
                              if (mounted && Navigator.of(context).canPop()) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error selecting server: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A4A),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(
                                color: const Color(0xFF00D4AA),
                                width: 2,
                              ) : null,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            countryName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (showGreenDot) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        locationName,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  ping,
                                  style: TextStyle(
                                    color: _pings[config.id] != null && _pings[config.id]! > 0 ?
                                           Colors.green : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 16,
                                  height: 12,
                                  child: CustomPaint(
                                    painter: SignalBarsPainter(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                  ),
          ),
        ],
      ),
    );
  }

  /// Returns a color based on the configuration type.
  Color _getConfigTypeColor(String configType) {
    switch (configType.toLowerCase()) {
      case 'vmess':
        return Colors.blue;
      case 'vless':
        return Colors.purple;
      case 'shadowsocks':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Returns the name of the subscription that the configuration belongs to.
  String _getSubscriptionName(V2RayConfig config) {
    final subscriptions = Provider.of<V2RayProvider>(
      context,
      listen: false,
    ).subscriptions;
    return subscriptions
        .firstWhere(
          (sub) => sub.configIds.contains(config.id),
          orElse: () => Subscription(
            id: '',
            name: 'Default Subscription',
            url: '',
            lastUpdated: DateTime.now(),
            configIds: [],
          ),
        )
        .name;
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

/// Shows the server selection screen.
void showServerSelectionScreen({
  required BuildContext context,
  required List<V2RayConfig> configs,
  required V2RayConfig? selectedConfig,
  required bool isConnecting,
  required Future<void> Function(V2RayConfig) onConfigSelected,
}) {
  final provider = Provider.of<V2RayProvider>(context, listen: false);
  if (provider.activeConfig != null) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: Text(
          context.tr(TranslationKeys.serverSelectionConnectionActive),
        ),
        content: Text(
          context.tr(TranslationKeys.serverSelectionDisconnectFirst),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('common.ok'),
              style: const TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServerSelectionScreen(
        configs: configs,
        selectedConfig: selectedConfig,
        isConnecting: isConnecting,
        onConfigSelected: onConfigSelected,
      ),
    ),
  );
}