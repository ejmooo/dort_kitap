// stats_provider: okuma istatistikleri ve günlük seri (streak).
// Açılan sûreler ile Kitab-ı Mukaddes bölümleri kaydedilir; her okuma günü
// seriyi ilerletir. Tamamı shared_preferences ile yerelde saklanır — hiçbir
// veri dışarı gönderilmez.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gün anahtarı: yerel saate göre "yyyy-mm-dd". Seri hesabı yalnızca takvim
/// gününe bakar, saate değil.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class ReadingStats {
  /// Kesintisiz okuma günü sayısı.
  final int currentStreak;

  /// Bugüne kadarki en uzun seri.
  final int bestStreak;

  /// Uygulamada okuma yapılan toplam farklı gün.
  final int totalDays;

  /// Açılan sûre numaraları.
  final Set<int> surahs;

  /// Açılan Kitab-ı Mukaddes bölümleri, "kitapNo:bölümIndeksi" biçiminde.
  final Set<String> chapters;

  /// Son okuma günü (yyyy-mm-dd); hiç okunmadıysa null.
  final String? lastDay;

  /// Okuma yapılan günlerin anahtarları — takvim şeridi için. Son bir yılla
  /// sınırlıdır, sonsuza kadar büyümesin diye.
  final Set<String> days;

  const ReadingStats({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalDays = 0,
    this.surahs = const {},
    this.chapters = const {},
    this.lastDay,
    this.days = const {},
  });

  bool get isEmpty => totalDays == 0 && surahs.isEmpty && chapters.isEmpty;

  /// Seri bugün veya dün sürüyorsa canlıdır. Dünden beri okunmamışsa sayaç
  /// hâlâ eski değeri tutar; kullanıcıya "kopmuş" göstermek için bu kullanılır.
  bool get streakAlive {
    if (lastDay == null) return false;
    final now = DateTime.now();
    final today = dayKey(now);
    final yesterday = dayKey(DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1)));
    return lastDay == today || lastDay == yesterday;
  }

  bool get readToday => lastDay == dayKey(DateTime.now());

  ReadingStats copyWith({
    int? currentStreak,
    int? bestStreak,
    int? totalDays,
    Set<int>? surahs,
    Set<String>? chapters,
    String? lastDay,
    Set<String>? days,
  }) {
    return ReadingStats(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalDays: totalDays ?? this.totalDays,
      surahs: surahs ?? this.surahs,
      chapters: chapters ?? this.chapters,
      lastDay: lastDay ?? this.lastDay,
      days: days ?? this.days,
    );
  }

  /// Son [count] günün okunup okunmadığı — bugün en sonda olacak şekilde.
  List<bool> recentDays(int count) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return List.generate(count, (i) {
      final d = base.subtract(Duration(days: count - 1 - i));
      return days.contains(dayKey(d));
    });
  }
}

class StatsNotifier extends Notifier<ReadingStats> {
  static const _kStreak = 'st_streak';
  static const _kBest = 'st_best';
  static const _kDays = 'st_days';
  static const _kLastDay = 'st_last_day';
  static const _kSurahs = 'st_surahs';
  static const _kChapters = 'st_chapters';
  static const _kDayLog = 'st_day_log';

  /// Gün kaydı en fazla bir yıl tutulur.
  static const _maxDayLog = 366;

  SharedPreferences? _prefs;
  Future<void>? _ready;

  @override
  ReadingStats build() {
    _ready = _load();
    return const ReadingStats();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    state = ReadingStats(
      currentStreak: p.getInt(_kStreak) ?? 0,
      bestStreak: p.getInt(_kBest) ?? 0,
      totalDays: p.getInt(_kDays) ?? 0,
      lastDay: p.getString(_kLastDay),
      surahs: (p.getStringList(_kSurahs) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet(),
      chapters: (p.getStringList(_kChapters) ?? const []).toSet(),
      days: (p.getStringList(_kDayLog) ?? const []).toSet(),
    );
  }

  /// Kayıt işlemleri yükleme bitmeden çağrılabilir (sayfa açılışı prefs'ten
  /// hızlıdır); beklemezsek okunmamış eski değerin üzerine yazardık.
  Future<SharedPreferences> _prefsReady() async {
    await _ready;
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// Bugünü okuma günü olarak işaretler ve seriyi günceller.
  Future<void> _touchDay(SharedPreferences p) async {
    final now = DateTime.now();
    final today = dayKey(now);
    if (state.lastDay == today) return; // gün içinde ilk kayıttan sonrası

    final yesterday = dayKey(
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1)));
    // Dün okunmuşsa seri devam eder; aradan gün atlandıysa baştan başlar.
    final streak = state.lastDay == yesterday ? state.currentStreak + 1 : 1;
    final best = streak > state.bestStreak ? streak : state.bestStreak;

    // Sıralı tutulup baştan kırpılır: en eski günler düşer, son yıl kalır.
    final log = [...state.days, today]..sort();
    if (log.length > _maxDayLog) log.removeRange(0, log.length - _maxDayLog);

    state = state.copyWith(
      currentStreak: streak,
      bestStreak: best,
      totalDays: state.totalDays + 1,
      lastDay: today,
      days: log.toSet(),
    );
    await p.setStringList(_kDayLog, log);
    await p.setInt(_kStreak, streak);
    await p.setInt(_kBest, best);
    await p.setInt(_kDays, state.totalDays);
    await p.setString(_kLastDay, today);
  }

  Future<void> recordSurah(int number) async {
    final p = await _prefsReady();
    await _touchDay(p);
    if (state.surahs.contains(number)) return;
    final next = {...state.surahs, number};
    state = state.copyWith(surahs: next);
    await p.setStringList(_kSurahs, next.map((e) => e.toString()).toList());
  }

  Future<void> recordChapter(int bookNr, int chapterIndex) async {
    final p = await _prefsReady();
    await _touchDay(p);
    final key = '$bookNr:$chapterIndex';
    if (state.chapters.contains(key)) return;
    final next = {...state.chapters, key};
    state = state.copyWith(chapters: next);
    await p.setStringList(_kChapters, next.toList());
  }

  /// İstatistikleri sıfırlar (ayarlardan, onay sorulduktan sonra).
  Future<void> reset() async {
    final p = await _prefsReady();
    state = const ReadingStats();
    await p.remove(_kStreak);
    await p.remove(_kBest);
    await p.remove(_kDays);
    await p.remove(_kLastDay);
    await p.remove(_kSurahs);
    await p.remove(_kChapters);
    await p.remove(_kDayLog);
  }
}

final statsProvider =
    NotifierProvider<StatsNotifier, ReadingStats>(StatsNotifier.new);
