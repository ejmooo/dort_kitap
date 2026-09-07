// notifications: günlük "günün konusu" hatırlatıcısı.
//
// Bildirim metni her gün değiştiği için tekrarlayan tek bir bildirim
// kuramıyoruz (tekrarlayan bildirimlerin içeriği sabittir). Bunun yerine
// önümüzdeki [_horizonDays] gün için ayrı ayrı bildirim planlanır ve
// uygulama her açıldığında pencere yeniden doldurulur. Kullanıcı uygulamayı
// bir hafta hiç açmazsa hatırlatıcılar susar — bu bilinçli bir denge.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/theme_cluster.dart';
import 'daily_topic.dart';

class DailyReminders {
  DailyReminders._();

  static final DailyReminders instance = DailyReminders._();

  static const int _baseId = 4100; // bu özelliğe ayrılmış id aralığı
  static const int _horizonDays = 7;
  static const String _channelId = 'daily_topic';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Yalnızca Android ve iOS için yapılandırıldı (init ayarları, manifest
  /// alıcıları). Web ve masaüstünde sessizce devre dışı — yarım yapılandırmayla
  /// başlatıp çalışma anında patlamaktansa özelliği hiç göstermemek daha iyi.
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureReady() async {
    if (_ready || !supported) return;
    tzdata.initializeTimeZones();
    // Cihazın saat dilimi olmadan zonedSchedule yanlış saatte tetiklenir.
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Sistem bildirim iznini ister. Kullanıcı reddederse false döner.
  Future<bool> requestPermission() async {
    if (!supported) return false;
    await _ensureReady();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  /// Planlanmış tüm hatırlatıcıları siler.
  Future<void> cancelAll() async {
    if (!supported) return;
    await _ensureReady();
    for (var i = 0; i < _horizonDays; i++) {
      await _plugin.cancel(id: _baseId + i);
    }
  }

  /// Önümüzdeki günler için hatırlatıcıları yeniden kurar.
  ///
  /// [hour]/[minute] kullanıcının seçtiği saat; [themes] günün konusunu
  /// belirlemek için kullanılır (akış sayfasıyla aynı formül).
  Future<void> schedule({
    required int hour,
    required int minute,
    required List<ThemeCluster> themes,
  }) async {
    if (!supported || themes.isEmpty) return;
    await _ensureReady();
    await cancelAll();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Günün konusu',
        channelDescription: 'Her gün bir karşılaştırmalı konu hatırlatması',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < _horizonDays; i++) {
      final day = now.add(Duration(days: i));
      final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
      // Bugünün saati geçtiyse bugünü atla; geçmişe bildirim kurulamaz.
      if (!when.isAfter(now)) continue;

      final topic = themes[dailyTopicIndex(when, themes.length)];
      await _plugin.zonedSchedule(
        id: _baseId + i,
        title: 'Günün konusu: ${topic.title}',
        body: topic.summary.isNotEmpty
            ? topic.summary
            : 'Dört kitabın bu konuyu nasıl ele aldığına bak.',
        scheduledDate: when,
        notificationDetails: details,
        // Kesin alarm izni (SCHEDULE_EXACT_ALARM) istemiyoruz; okuma
        // hatırlatıcısı için birkaç dakikalık sapma önemsiz.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
