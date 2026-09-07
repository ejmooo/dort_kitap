// bible_parallels_provider: parallels.json'daki (Kur'an ayeti -> Kitab-ı Mukaddes)
// eşleşmelerini TERS çevirir; böylece Tevrat/Zebur/İncil okurken de o ayetin
// Kur'an'daki karşılığı görünür. Anahtar biçimi: "kitapNr:bölüm:ayet".

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/parallel.dart';
import 'quran_provider.dart';

/// parallels.json referanslarındaki Türkçe kitap adı -> bible.json kitap numarası.
/// (Adlar build_themes.py'deki TR_BOOK çevirisiyle birebir; bible.json'daki
/// "Mısır'dan Çıkış"/"Sayılar"/"Mezmurlar" gibi ad farkları numarayla aşılır.)
const Map<String, int> _refBookNr = {
  'Yaratılış': 1,
  'Çıkış': 2,
  'Levililer': 3,
  'Çölde Sayım': 4,
  "Yasa'nın Tekrarı": 5,
  'Mezmur': 19,
  'Matta': 40,
  'Markos': 41,
  'Luka': 42,
  'Yuhanna': 43,
};

final bibleParallelsProvider =
    FutureProvider<Map<String, List<Parallel>>>((ref) async {
  final parallels = await ref.watch(parallelsProvider.future);
  final quran = await ref.watch(quranProvider.future);
  final surahNames = {for (final s in quran) s.number: s.name};

  final result = <String, List<Parallel>>{};

  parallels.forEach((quranKey, list) {
    final surahNumber = int.tryParse(quranKey.split(':').first) ?? 0;
    final surahName = surahNames[surahNumber] ?? '';
    final quranReference =
        surahName.isEmpty ? quranKey : '$surahName $quranKey';

    for (final p in list) {
      // "Çölde Sayım 6:24-26" -> kitap adı + bölüm:ayet(-aralık)
      final split = p.reference.lastIndexOf(' ');
      if (split < 0) continue;
      final bookNr = _refBookNr[p.reference.substring(0, split)];
      if (bookNr == null) continue;
      final chapterVerse = p.reference.substring(split + 1).split(':');
      if (chapterVerse.length != 2) continue;
      final chapter = int.tryParse(chapterVerse[0]);
      if (chapter == null) continue;

      // Ayet aralığını tek tek ayetlere aç.
      final versePart = chapterVerse[1].split('-');
      final start = int.tryParse(versePart.first);
      final end =
          versePart.length > 1 ? int.tryParse(versePart.last) : start;
      if (start == null || end == null) continue;

      for (var v = start; v <= end; v++) {
        final key = '$bookNr:$chapter:$v';
        final bucket = result.putIfAbsent(key, () => []);
        // Aynı Kur'an referansını iki kez ekleme.
        if (bucket.any((e) => e.reference == quranReference)) continue;
        bucket.add(Parallel(
          book: 'kuran',
          reference: quranReference,
          note: p.note,
          origin: p.origin,
          themeId: p.themeId,
        ));
      }
    }
  });

  return result;
});
