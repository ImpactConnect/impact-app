import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  LanguageProvider(this._prefs) {
    _loadLanguage();
  }
  static const String _languageKey = 'selected_language';
  final SharedPreferences _prefs;
  late Locale _currentLocale;

  static const Map<String, Locale> supportedLocales = {
    'English': Locale('en'),
    'Spanish': Locale('es'),
    'French': Locale('fr'),
    'German': Locale('de'),
    'Chinese': Locale('zh'),
  };

  Locale get currentLocale => _currentLocale;
  String get currentLanguage => _getLanguageName(_currentLocale);

  void _loadLanguage() {
    final savedLanguage = _prefs.getString(_languageKey) ?? 'English';
    _currentLocale = supportedLocales[savedLanguage] ?? const Locale('en');
    notifyListeners();
  }

  Future<void> setLanguage(String languageName) async {
    if (supportedLocales.containsKey(languageName)) {
      _currentLocale = supportedLocales[languageName]!;
      await _prefs.setString(_languageKey, languageName);
      notifyListeners();
    }
  }

  String _getLanguageName(Locale locale) {
    return supportedLocales.entries
        .firstWhere(
          (entry) => entry.value == locale,
          orElse: () => const MapEntry('English', Locale('en')),
        )
        .key;
  }

  List<String> get supportedLanguages => supportedLocales.keys.toList();
}
