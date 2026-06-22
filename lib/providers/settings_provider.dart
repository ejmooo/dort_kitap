// settings_provider: kullanıcı okuma ayarları (tema modu + yazı boyutu).
// shared_preferences ile kalıcıdır; uygulama genelinde uygulanır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final double textScale;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
  });

  AppSettings copyWith({ThemeMode? themeMode, double? textScale}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kMode = 'theme_mode';
  static const _kScale = 'text_scale';
  static const double minScale = 0.85;
  static const double maxScale = 1.6;

  SharedPreferences? _prefs;

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final modeIndex = _prefs!.getInt(_kMode);
    final scale = _prefs!.getDouble(_kScale);
    state = AppSettings(
      themeMode: modeIndex != null && modeIndex < ThemeMode.values.length
          ? ThemeMode.values[modeIndex]
          : ThemeMode.system,
      textScale: scale ?? 1.0,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt(_kMode, mode.index);
  }

  Future<void> setTextScale(double scale) async {
    final clamped = scale.clamp(minScale, maxScale);
    state = state.copyWith(textScale: clamped);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble(_kScale, clamped);
  }

  void increaseText() => setTextScale(state.textScale + 0.1);
  void decreaseText() => setTextScale(state.textScale - 0.1);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
