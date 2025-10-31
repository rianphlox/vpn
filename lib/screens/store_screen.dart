// This file contains the implementation of the StoreScreen, which allows users to browse and add V2Ray subscriptions from a remote source.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/v2ray_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/error_snackbar.dart';
import '../utils/app_localizations.dart';

/// A screen that displays a list of V2Ray subscriptions from a remote store.
/// Users can search for subscriptions, copy their URLs, and add them to the app.
class StoreScreen extends StatefulWidget {
  /// A callback function that is called when a tab is selected.
  final Function(int)? onTabSelected;

  /// Creates a new instance of the [StoreScreen].
  const StoreScreen({super.key, this.onTabSelected});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  /// The URL of the remote store.
  final String _storeUrl =
      'https://raw.githubusercontent.com/darkvpnapp/CloudflarePlus/refs/heads/main/store.json';

  /// The list of all store items.
  List<dynamic> _storeItems = [];

  /// The list of filtered store items.
  List<dynamic> _filteredItems = [];

  /// Whether the screen is currently loading data.
  bool _isLoading = true;

  /// The error message to display, if any.
  String _errorMessage = '';

  /// The controller for the search text field.
  final TextEditingController _searchController = TextEditingController();

  /// The current search query.
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  /// Fetches the store data from the remote URL.
  Future<void> _fetchStoreData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http
          .get(Uri.parse(_storeUrl))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw Exception(
                context.tr(TranslationKeys.errorConnectionTimeout),
              );
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _storeItems = data;
          _filteredItems = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = context.tr(
            TranslationKeys.storeScreenFailedToLoad,
            parameters: {'code': response.statusCode.toString()},
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            context.tr(TranslationKeys.errorNetwork) + ': ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Filters the store items based on the search query.
  void _filterItems() {
    setState(() {
      _filteredItems = _storeItems.where((item) {
        final name = item['name'].toString().toLowerCase();
        final dev = item['dev'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();

        return name.contains(query) || dev.contains(query);
      }).toList();
    });
  }

  /// Copies the given text to the clipboard.
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr(TranslationKeys.storeScreenUrlCopied))),
    );
  }

  /// Adds a new subscription to the app.
  Future<void> _addToSubscriptions(String name, String url) async {
    final provider = Provider.of<V2RayProvider>(context, listen: false);

    try {
      // Check if subscription with this name already exists
      if (provider.subscriptions.any((s) => s.name == name)) {
        ErrorSnackbar.show(
          context,
          context.tr(TranslationKeys.storeScreenSubscriptionExists),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(TranslationKeys.storeScreenAddingSubscription),
          ),
        ),
      );

      // Add subscription
      await provider.addSubscription(name, url.trim());

      // Check if there was an error
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
              context.tr(TranslationKeys.storeScreenSubscriptionAdded),
            ),
          ),
        );
      }
    } catch (e) {
      ErrorSnackbar.show(
        context,
        context.tr(TranslationKeys.errorUnknown) + ': ${e.toString()}',
      );
    }
  }

  /// Launches the Telegram URL.
  Future<void> _launchTelegramUrl() async {
    final Uri url = Uri.parse('https://t.me/h3dev');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ErrorSnackbar.show(
          context,
          context.tr(TranslationKeys.storeScreenCouldNotLaunch),
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
                  context.tr(TranslationKeys.storeScreenAddNew),
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
                    context.tr(TranslationKeys.storeScreenContactTelegram),
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
                    context.tr(TranslationKeys.storeScreenCancel),
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
                    const Text(
                      'Store',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchStoreData,
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A4A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search subscriptions...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _filterItems();
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00D4AA),
                        ),
                      )
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Connection Error',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: 200,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _fetchStoreData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00D4AA),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                      child: const Text(
                                        'Try Again',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _filteredItems.isEmpty
                            ? const Center(
                                child: Text(
                                  'No subscriptions available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                                itemCount: _filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = _filteredItems[index];
                                  return _buildStoreCard(context, item);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a card widget for a store item.
  Widget _buildStoreCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A4A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SUBSCRIPTION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00D4AA),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.grey, size: 18),
                  onPressed: () => _copyToClipboard(item['url'] ?? ''),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subscription name
            Text(
              item['name'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Developer
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 6),
                Text(
                  item['dev'] ?? 'Unknown Developer',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // URL container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['url'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Add button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add to App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _addToSubscriptions(
                  item['name'] ?? 'Unknown',
                  item['url'] ?? '',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}