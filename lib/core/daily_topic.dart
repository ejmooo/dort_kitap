// daily_topic: "günün konusu" seçimi. Akış sayfası ve günlük bildirim aynı
// formülü kullanmalı — yoksa kullanıcı bildirimde bir konu, uygulamada başka
// bir konu görür.

/// Sayacın başlangıcı. Değiştirilirse herkesin "günün konusu" kayar.
final DateTime kTopicEpoch = DateTime(2020, 1, 1);

/// [day] için tema listesindeki indeks. Gün değişmedikçe sonuç sabittir, bu
/// yüzden ileri tarihler için de önceden hesaplanabilir (bildirim planlaması).
int dailyTopicIndex(DateTime day, int count) {
  if (count <= 0) return 0;
  final days = DateTime(day.year, day.month, day.day).difference(kTopicEpoch).inDays;
  return days % count;
}
