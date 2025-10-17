import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Language state
class LanguageState {
  final Locale locale;
  final bool isLoading;

  const LanguageState({
    required this.locale,
    this.isLoading = false,
  });

  LanguageState copyWith({
    Locale? locale,
    bool? isLoading,
  }) {
    return LanguageState(
      locale: locale ?? this.locale,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Language provider
class LanguageNotifier extends StateNotifier<LanguageState> {
  static const String _languageKey = 'selected_language';
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('fr', ''), // French
    Locale('es', ''), // Spanish
  ];

  LanguageNotifier() : super(const LanguageState(locale: Locale('en', ''))) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        final locale = Locale(languageCode, '');
        if (supportedLocales.contains(locale)) {
          state = state.copyWith(locale: locale);
        }
      }
    } catch (e) {
      // If loading fails, keep default language
      print('Failed to load saved language: $e');
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    if (!supportedLocales.contains(locale)) {
      return;
    }

    state = state.copyWith(isLoading: true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      
      state = state.copyWith(
        locale: locale,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Failed to save language: $e');
    }
  }

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      default:
        return locale.languageCode;
    }
  }

  String getLanguageNativeName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      default:
        return locale.languageCode;
    }
  }
}

// Providers
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});

final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(languageProvider).locale;
});
