import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State model for Locale and Region
class LocaleState {
  final Locale locale;
  final String region;

  const LocaleState({
    required this.locale,
    required this.region,
  });

  LocaleState copyWith({Locale? locale, String? region}) {
    return LocaleState(
      locale: locale ?? this.locale,
      region: region ?? this.region,
    );
  }
}

class LocaleNotifier extends Notifier<LocaleState> {
  @override
  LocaleState build() {
    // Initial state, will be updated by loadPreferences
    // We trigger loadPreferences after build.
    // Ideally we should use AsyncNotifier for async initialization, 
    // but for simple sync default + async update, this works.
    _loadPreferences();
    return const LocaleState(locale: Locale('tr', 'TR'), region: 'TR');
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'tr';
    final countryCode = prefs.getString('countryCode') ?? 'TR';
    final region = prefs.getString('region') ?? 'TR';

    state = LocaleState(
      locale: Locale(languageCode, countryCode),
      region: region,
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    if (locale.countryCode != null) {
      await prefs.setString('countryCode', locale.countryCode!);
    }
  }

  Future<void> setRegion(String region) async {
    state = state.copyWith(region: region);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('region', region);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, LocaleState>(() {
  return LocaleNotifier();
});
