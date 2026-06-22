// reading_progress_provider: Kur'an ve Kitab-ı Mukaddes'te en son okunan yeri
// hatırlar (shared_preferences ile kalıcı) — "kaldığın yere devam" için.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingProgress {
  final int? quranSurah;
  final String? quranSurahName;
  final int? bibleBookNr;
  final String? bibleBookName;
  final int? bibleChapterIndex; // listedeki konum
  final int? bibleChapterNo; // görünen bölüm numarası

  const ReadingProgress({
    this.quranSurah,
    this.quranSurahName,
    this.bibleBookNr,
    this.bibleBookName,
    this.bibleChapterIndex,
    this.bibleChapterNo,
  });

  bool get hasQuran => quranSurah != null;
  bool get hasBible => bibleBookNr != null && bibleChapterIndex != null;

  ReadingProgress copyWith({
    int? quranSurah,
    String? quranSurahName,
    int? bibleBookNr,
    String? bibleBookName,
    int? bibleChapterIndex,
    int? bibleChapterNo,
  }) {
    return ReadingProgress(
      quranSurah: quranSurah ?? this.quranSurah,
      quranSurahName: quranSurahName ?? this.quranSurahName,
      bibleBookNr: bibleBookNr ?? this.bibleBookNr,
      bibleBookName: bibleBookName ?? this.bibleBookName,
      bibleChapterIndex: bibleChapterIndex ?? this.bibleChapterIndex,
      bibleChapterNo: bibleChapterNo ?? this.bibleChapterNo,
    );
  }
}

class ReadingProgressNotifier extends Notifier<ReadingProgress> {
  SharedPreferences? _prefs;

  @override
  ReadingProgress build() {
    _load();
    return const ReadingProgress();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    state = ReadingProgress(
      quranSurah: p.getInt('rp_quran_surah'),
      quranSurahName: p.getString('rp_quran_name'),
      bibleBookNr: p.getInt('rp_bible_book'),
      bibleBookName: p.getString('rp_bible_name'),
      bibleChapterIndex: p.getInt('rp_bible_ci'),
      bibleChapterNo: p.getInt('rp_bible_cn'),
    );
  }

  Future<void> setQuran(int surah, String name) async {
    state = state.copyWith(quranSurah: surah, quranSurahName: name);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt('rp_quran_surah', surah);
    await _prefs!.setString('rp_quran_name', name);
  }

  Future<void> setBible(
      int bookNr, String name, int chapterIndex, int chapterNo) async {
    state = state.copyWith(
      bibleBookNr: bookNr,
      bibleBookName: name,
      bibleChapterIndex: chapterIndex,
      bibleChapterNo: chapterNo,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setInt('rp_bible_book', bookNr);
    await _prefs!.setString('rp_bible_name', name);
    await _prefs!.setInt('rp_bible_ci', chapterIndex);
    await _prefs!.setInt('rp_bible_cn', chapterNo);
  }
}

final readingProgressProvider =
    NotifierProvider<ReadingProgressNotifier, ReadingProgress>(
        ReadingProgressNotifier.new);
