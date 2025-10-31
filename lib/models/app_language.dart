class AppLanguage {
  final String name;
  final String code;
  final String flag;
  final String direction; // 'ltr' or 'rtl'

  const AppLanguage({
    required this.name,
    required this.code,
    required this.flag,
    required this.direction,
  });

  bool get isRtl => direction == 'rtl';

  factory AppLanguage.fromJson(Map<String, dynamic> json) {
    final language = json['language'] as Map<String, dynamic>;
    return AppLanguage(
      name: language['name'] as String,
      code: language['code'] as String,
      flag: language['flag'] as String,
      direction: language['direction'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': {
        'name': name,
        'code': code,
        'flag': flag,
        'direction': direction,
      },
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppLanguage && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'AppLanguage(name: $name, code: $code, flag: $flag, direction: $direction)';
  }

  // Predefined languages
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(name: 'English', code: 'en', flag: '🇺🇸', direction: 'ltr'),
    AppLanguage(name: 'فارسی', code: 'fa', flag: '🦁', direction: 'rtl'),
    AppLanguage(name: 'Русский', code: 'ru', flag: '🇷🇺', direction: 'ltr'),
    AppLanguage(name: '中文', code: 'zh', flag: '🇨🇳', direction: 'ltr'),
    AppLanguage(name: 'Español', code: 'es', flag: '🇪🇸', direction: 'ltr'),
    AppLanguage(name: 'Français', code: 'fr', flag: '🇫🇷', direction: 'ltr'),
    AppLanguage(name: 'العربية', code: 'ar', flag: '🇸🇦', direction: 'rtl'),
    AppLanguage(name: 'Türkçe', code: 'tr', flag: '🇹🇷', direction: 'ltr'),
  ];

  static AppLanguage getByCode(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => supportedLanguages.first, // Default to English
    );
  }

  static List<String> get supportedLocales {
    return supportedLanguages.map((lang) => lang.code).toList();
  }
}
