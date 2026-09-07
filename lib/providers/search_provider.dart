// search_provider: tam metin arama için önceden hazırlanmış dizin. Tüm ayetlerin
// küçük harfe çevrilmiş kopyası BİR KEZ üretilir; böylece her tuş vuruşunda
// ~37 bin metinde tekrar toLowerCase çağrılmaz.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bible_models.dart';
import '../models/quran_models.dart';
import 'bible_provider.dart';
import 'quran_provider.dart';

class SearchEntry {
  final String reference;
  final String text; // gösterilecek orijinal metin
  final String lower; // arama için önceden küçültülmüş
  final QuranSurah? surah; // Kur'an sonucu ise
  final BibleBook? book; // Kitab-ı Mukaddes sonucu ise
  final int? chapterIndex;

  const SearchEntry({
    required this.reference,
    required this.text,
    required this.lower,
    this.surah,
    this.book,
    this.chapterIndex,
  });

  bool get isQuran => surah != null;
}

final searchIndexProvider = FutureProvider<List<SearchEntry>>((ref) async {
  final quran = await ref.watch(quranProvider.future);
  final bible = await ref.watch(bibleProvider.future);

  final entries = <SearchEntry>[];
  for (final surah in quran) {
    for (final ayah in surah.ayahs) {
      entries.add(SearchEntry(
        reference: '${surah.name} ${surah.number}:${ayah.number}',
        text: ayah.turkish,
        lower: ayah.turkish.toLowerCase(),
        surah: surah,
      ));
    }
  }
  for (final book in bible) {
    for (var ci = 0; ci < book.chapters.length; ci++) {
      final chapter = book.chapters[ci];
      for (final verse in chapter.verses) {
        entries.add(SearchEntry(
          reference: '${book.name} ${chapter.number}:${verse.number}',
          text: verse.text,
          lower: verse.text.toLowerCase(),
          book: book,
          chapterIndex: ci,
        ));
      }
    }
  }
  return entries;
});
