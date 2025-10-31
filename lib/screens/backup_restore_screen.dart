import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/language_provider.dart';
import '../utils/app_localizations.dart';
import '../theme/app_theme.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptions = prefs.getStringList('v2ray_subscriptions') ?? [];
      final configs = prefs.getStringList('v2ray_configs') ?? [];
      final blockedApps = prefs.getStringList('blocked_apps') ?? [];

      final data = {
        'subscriptions': subscriptions,
        'configs': configs,
        'blocked_apps': blockedApps,
      };

      final jsonString = jsonEncode(data);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'settings-pc-$timestamp.json';

      // Get the Downloads directory
      Directory? downloadsDir;
      try {
        downloadsDir = Directory('/storage/emulated/0/Download');
        // Check if the directory exists, create it if it doesn't
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } catch (e) {
        // Fallback to temporary directory if Downloads is inaccessible
        downloadsDir = await getTemporaryDirectory();
      }

      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(jsonString);

      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.backupRestoreBackupSaved,
          parameters: {'fileName': 'Downloads/$fileName'},
        );
      });
    } catch (e) {
      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.backupRestoreErrorExporting,
          parameters: {'error': e.toString()},
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _statusMessage = context.tr(
            TranslationKeys.backupRestoreNoFileSelected,
          );
        });
        return;
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'v2ray_subscriptions',
        List<String>.from(data['subscriptions'] ?? []),
      );
      await prefs.setStringList(
        'v2ray_configs',
        List<String>.from(data['configs'] ?? []),
      );
      await prefs.setStringList(
        'blocked_apps',
        List<String>.from(data['blocked_apps'] ?? []),
      );

      setState(() {
        _statusMessage = context.tr(TranslationKeys.backupRestoreDataImported);
      });
    } catch (e) {
      setState(() {
        _statusMessage = context.tr(
          TranslationKeys.backupRestoreErrorImporting,
          parameters: {'error': e.toString()},
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Directionality(
          textDirection: languageProvider.textDirection,
          child: _buildBackupRestoreScreen(context),
        );
      },
    );
  }

  Widget _buildBackupRestoreScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(context.tr(TranslationKeys.backupRestoreTitle)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppTheme.cardDark,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(TranslationKeys.backupRestoreBackupData),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        TranslationKeys.backupRestoreBackupDescription,
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _exportData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              context.tr(
                                TranslationKeys.backupRestoreExportNow,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppTheme.cardDark,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(TranslationKeys.backupRestoreRestoreData),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        TranslationKeys.backupRestoreRestoreDescription,
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _importData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              context.tr(
                                TranslationKeys.backupRestoreImportNow,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('Error')
                      ? Colors.red
                      : AppTheme.connectedGreen,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
