import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_translations.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final notifier = LanguageNotifier();
  notifier._init(); // Initialize and load saved language
  return notifier;
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('bn'));

  static const String _prefKey = 'selected_language';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_prefKey);
    if (savedLanguage != null) {
      state = Locale(savedLanguage);
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
  }

  String translate(String key, Locale locale) {
    return AppTranslations.translations[locale.languageCode]?[key] ?? key;
  }
}

// সহজ ব্যবহারের জন্য একটি এক্সটেনশন
extension LanguageExtension on WidgetRef {
  String tr(String key) {
    // এখানে 'watch' ব্যবহার করায় ভাষা পরিবর্তন হলে রি-বিল্ড হবে
    final locale = watch(languageProvider);
    return read(languageProvider.notifier).translate(key, locale);
  }
}
