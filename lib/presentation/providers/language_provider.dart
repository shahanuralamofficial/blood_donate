import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_translations.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('bn')) {
    _init();
  }

  static const String _prefKey = 'selected_language';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_prefKey);

    if (savedLanguage != null) {
      state = Locale(savedLanguage);
    } else {
      // ডিফল্ট হিসেবে বাংলা সেট করা (যেহেতু অ্যাপটি বাংলাদেশের জন্য)
      state = const Locale('bn');
      
      // তবে সিস্টেম ল্যাঙ্গুয়েজ চেক করা (যদি ইউজার অন্য দেশে থাকে বা ইংলিশ প্রেফার করে)
      final systemLocale = PlatformDispatcher.instance.locale;
      if (systemLocale.languageCode == 'en') {
        // যদি সিস্টেম ল্যাঙ্গুয়েজ ইংলিশ হয়, তবে চাইলে ইংলিশও রাখা যেতে পারে। 
        // কিন্তু আপনার রিকোয়ারমেন্ট অনুযায়ী ডিফল্ট বাংলা রাখা হচ্ছে।
      }

      await prefs.setString(_prefKey, state.languageCode);
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
  }

  String translate(String key) {
    return AppTranslations.translations[state.languageCode]?[key] ?? key;
  }
}

// সহজ ব্যবহারের জন্য একটি এক্সটেনশন
extension LanguageExtension on WidgetRef {
  String tr(String key) {
    return read(languageProvider.notifier).translate(key);
  }
}

extension BuildContextLanguageExtension on dynamic {
  // ConsumerWidget এর বাইরে ব্যবহারের জন্য (যদি প্রয়োজন হয়)
}
