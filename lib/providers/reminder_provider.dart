// reminder_provider: günlük "günün konusu" hatırlatıcısının ayarı (açık/kapalı
// ve saat). Ayar değiştikçe planlanmış bildirimler yeniden kurulur.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications.dart';
import 'themes_provider.dart';

class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

class ReminderNotifier extends Notifier<ReminderSettings> {
  static const _kEnabled = 'rm_enabled';
  static const _kHour = 'rm_hour';
  static const _kMinute = 'rm_minute';

  SharedPreferences? _prefs;
  Future<void>? _ready;

  @override
  ReminderSettings build() {
    _ready = _load();
    return const ReminderSettings();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    state = ReminderSettings(
      enabled: p.getBool(_kEnabled) ?? false,
      hour: p.getInt(_kHour) ?? 20,
      minute: p.getInt(_kMinute) ?? 0,
    );
    // Bildirimler yalnızca ileriye dönük birkaç gün için kurulur; her açılışta
    // pencereyi yeniden doldurmak gerekir.
    if (state.enabled) await _reschedule();
  }

  Future<SharedPreferences> _prefsReady() async {
    await _ready;
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _reschedule() async {
    if (!state.enabled) {
      await DailyReminders.instance.cancelAll();
      return;
    }
    final themes = await ref.read(themesProvider.future);
    await DailyReminders.instance.schedule(
      hour: state.hour,
      minute: state.minute,
      themes: themes,
    );
  }

  /// Hatırlatıcıyı açar. İzin verilmezse açılmaz ve false döner — kullanıcıya
  /// "açık" görünüp hiç bildirim gelmemesinden iyidir.
  Future<bool> setEnabled(bool value) async {
    if (value) {
      final granted = await DailyReminders.instance.requestPermission();
      if (!granted) return false;
    }
    final p = await _prefsReady();
    state = state.copyWith(enabled: value);
    await p.setBool(_kEnabled, value);
    await _reschedule();
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    final p = await _prefsReady();
    state = state.copyWith(hour: hour, minute: minute);
    await p.setInt(_kHour, hour);
    await p.setInt(_kMinute, minute);
    await _reschedule();
  }
}

final reminderProvider =
    NotifierProvider<ReminderNotifier, ReminderSettings>(ReminderNotifier.new);
