import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Named accent color choices for the "theme (colors of texts)" setting
/// requested in the spec. Kept as a small fixed palette rather than a
/// free color picker — easier to guarantee readability against the
/// liquid glass surfaces in both light and dark mode.
enum AppAccentColor { blue, teal, coral, amber, purple }

extension AppAccentColorX on AppAccentColor {
  String get label {
    switch (this) {
      case AppAccentColor.blue:
        return 'Blue';
      case AppAccentColor.teal:
        return 'Teal';
      case AppAccentColor.coral:
        return 'Coral';
      case AppAccentColor.amber:
        return 'Amber';
      case AppAccentColor.purple:
        return 'Purple';
    }
  }

  Color get color {
    switch (this) {
      case AppAccentColor.blue:
        return const Color(0xFF378ADD);
      case AppAccentColor.teal:
        return const Color(0xFF1D9E75);
      case AppAccentColor.coral:
        return const Color(0xFFD85A30);
      case AppAccentColor.amber:
        return const Color(0xFFBA7517);
      case AppAccentColor.purple:
        return const Color(0xFF7F77DD);
    }
  }
}

class AppThemeState {
  final bool isDarkMode;
  final AppAccentColor accentColor;

  const AppThemeState({
    required this.isDarkMode,
    required this.accentColor,
  });

  AppThemeState copyWith({bool? isDarkMode, AppAccentColor? accentColor}) {
    return AppThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

const _prefsKeyDarkMode = 'app_is_dark_mode';
const _prefsKeyAccentColor = 'app_accent_color';

class ThemeNotifier extends Notifier<AppThemeState> {
  @override
  AppThemeState build() {
    // Default to dark mode + blue accent on first launch, then load any
    // saved preference asynchronously and update once available.
    _loadSaved();
    return const AppThemeState(
      isDarkMode: true,
      accentColor: AppAccentColor.blue,
    );
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDark = prefs.getBool(_prefsKeyDarkMode);
    final savedAccentIndex = prefs.getInt(_prefsKeyAccentColor);

    AppAccentColor accent = state.accentColor;
    if (savedAccentIndex != null &&
        savedAccentIndex >= 0 &&
        savedAccentIndex < AppAccentColor.values.length) {
      accent = AppAccentColor.values[savedAccentIndex];
    }

    state = AppThemeState(
      isDarkMode: savedDark ?? state.isDarkMode,
      accentColor: accent,
    );
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyDarkMode, value);
  }

  Future<void> setAccentColor(AppAccentColor color) async {
    state = state.copyWith(accentColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyAccentColor, color.index);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeState>(
  ThemeNotifier.new,
);