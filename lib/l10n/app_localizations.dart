import 'package:flutter/material.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_de.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('de'),
  ];

  // App Title
  String get appTitle;

  // Settings Screen
  String get settings;
  String get connection;
  String get security;
  String get general;
  String get about;

  // Connection Settings
  String get autoConnect;
  String get autoConnectDescription;
  String get protocol;
  String get protocolDescription;
  String get connectionLogs;
  String get connectionLogsDescription;

  // Security Settings
  String get killSwitch;
  String get killSwitchDescription;
  String get dnsProtection;
  String get dnsProtectionDescription;
  String get trustedNetworks;
  String get trustedNetworksDescription;
  String get appBypass;
  String get appBypassDescription;

  // General Settings
  String get notifications;
  String get notificationsDescription;
  String get language;
  String get clearCache;
  String get clearCacheDescription;

  // About Section
  String get version;
  String get privacyPolicy;
  String get privacyPolicyDescription;
  String get termsOfService;
  String get termsOfServiceDescription;
  String get helpSupport;
  String get helpSupportDescription;
  String get rateApp;
  String get rateAppDescription;

  // Dialog Content
  String get connectionLogsContent;
  String get trustedNetworksContent;
  String get appBypassContent;
  String get languageSettingsContent;
  String get clearCacheSuccess;
  String get clearCacheError;
  String get privacyPolicyContent;
  String get termsOfServiceContent;
  String get helpSupportContent;
  String get rateAppContent;
  String get ok;

  // Language Names
  String get english;
  String get spanish;
  String get german;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'es':
        return AppLocalizationsEs();
      case 'de':
        return AppLocalizationsDe();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}