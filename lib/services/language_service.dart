// This file contains the implementation of the LanguageService, which handles language-related operations such as saving and retrieving the selected language, loading translations, and getting the device's language.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_language.dart';

/// A service that handles language-related operations.
class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguageCode = 'en';

  /// Gets the saved language from storage.
  Future<AppLanguage> getSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageKey) ?? _defaultLanguageCode;
      return AppLanguage.getByCode(savedCode);
    } catch (e) {
      return AppLanguage.getByCode(_defaultLanguageCode);
    }
  }

  /// Saves the selected language to storage.
  Future<bool> saveLanguage(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_languageKey, language.code);
    } catch (e) {
      return false;
    }
  }

  /// Gets the list of available languages.
  Future<List<AppLanguage>> getAvailableLanguages() async {
    try {
      return AppLanguage.supportedLanguages;
    } catch (e) {
      return [AppLanguage.getByCode(_defaultLanguageCode)];
    }
  }

  /// Loads the translations for a specific language.
  Future<Map<String, dynamic>> loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/languages/$languageCode.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return jsonMap;
    } catch (e) {
      // If loading fails, try to load default language
      if (languageCode != _defaultLanguageCode) {
        return await loadTranslations(_defaultLanguageCode);
      }
      // Return empty map if even default fails
      return {};
    }
  }

  /// Gets the device's locale.
  String getDeviceLocale() {
    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      return locale.languageCode;
    } catch (e) {
      return _defaultLanguageCode;
    }
  }

  /// Checks if a language is supported.
  bool isLanguageSupported(String languageCode) {
    return AppLanguage.supportedLocales.contains(languageCode);
  }

  /// Gets the best matching language for the device.
  Future<AppLanguage> getDeviceLanguage() async {
    final deviceLocale = getDeviceLocale();

    if (isLanguageSupported(deviceLocale)) {
      return AppLanguage.getByCode(deviceLocale);
    }

    // If exact match not found, check for language family (e.g., 'en-US' -> 'en')
    for (final supportedCode in AppLanguage.supportedLocales) {
      if (deviceLocale.startsWith(supportedCode)) {
        return AppLanguage.getByCode(supportedCode);
      }
    }

    return AppLanguage.getByCode(_defaultLanguageCode);
  }

  /// Initializes the language on the first app launch.
  Future<AppLanguage> initializeLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageKey);

      if (savedCode != null) {
        // User has previously selected a language
        return AppLanguage.getByCode(savedCode);
      } else {
        // First time launch, use device language
        final deviceLanguage = await getDeviceLanguage();
        await saveLanguage(deviceLanguage);
        return deviceLanguage;
      }
    } catch (e) {
      return AppLanguage.getByCode(_defaultLanguageCode);
    }
  }

  /// Clears the saved language (resets to default).
  Future<bool> clearSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_languageKey);
    } catch (e) {
      return false;
    }
  }
}