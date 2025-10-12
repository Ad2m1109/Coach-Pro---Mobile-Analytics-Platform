import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier with ChangeNotifier {
  Locale? _locale;

  LocaleNotifier(this._locale);

  Locale? get locale => _locale;

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
    if (newLocale.countryCode != null) {
      await prefs.setString('country_code', newLocale.countryCode!);
    } else {
      await prefs.remove('country_code');
    }
  }

  static Future<Locale> getLocaleFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    final countryCode = prefs.getString('country_code');
    return Locale(languageCode, countryCode);
  }
}