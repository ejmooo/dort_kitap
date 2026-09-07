// json_loader: assets/data altındaki JSON verilerini (temalar, tüm Kuran,
// Kitab-ı Mukaddes ve ayet düzeyi benzerlik indeksi) rootBundle'dan okuyup
// modellere çevirir. Büyük dosyalar UI'yi kilitlememek için compute() ile
// arka isolate'te parse edilir (web'de compute aynı iş parçacığında çalışır).

import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

import '../models/bible_models.dart';
import '../models/parallel.dart';
import '../models/quran_models.dart';
import '../models/theme_cluster.dart';

const String kThemesAssetPath = 'assets/data/themes.json';
const String kQuranAssetPath = 'assets/data/quran.json';
const String kBibleAssetPath = 'assets/data/bible.json';
const String kParallelsAssetPath = 'assets/data/parallels.json';

// Parse fonksiyonları compute() ile kullanılabilmek için üst düzey tanımlı.

List<ThemeCluster> parseThemeClusters(String raw) {
  final decoded = json.decode(raw);
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(ThemeCluster.fromJson)
      .toList();
}

List<QuranSurah> parseQuran(String raw) {
  final decoded = json.decode(raw);
  final surahs = decoded is Map<String, dynamic> ? decoded['surahs'] : decoded;
  if (surahs is! List) return const [];
  return surahs
      .whereType<Map<String, dynamic>>()
      .map(QuranSurah.fromJson)
      .toList();
}

List<BibleBook> parseBible(String raw) {
  final decoded = json.decode(raw);
  final books = decoded is Map<String, dynamic> ? decoded['books'] : decoded;
  if (books is! List) return const [];
  return books
      .whereType<Map<String, dynamic>>()
      .map(BibleBook.fromJson)
      .toList();
}

Map<String, List<Parallel>> parseParallels(String raw) {
  final decoded = json.decode(raw);
  if (decoded is! Map<String, dynamic>) return const {};
  final result = <String, List<Parallel>>{};
  decoded.forEach((key, value) {
    if (value is List) {
      result[key] = value
          .whereType<Map<String, dynamic>>()
          .map(Parallel.fromJson)
          .toList();
    }
  });
  return result;
}

Future<List<ThemeCluster>> loadThemeClusters() async {
  final raw = await rootBundle.loadString(kThemesAssetPath);
  return compute(parseThemeClusters, raw);
}

Future<List<QuranSurah>> loadQuran() async {
  final raw = await rootBundle.loadString(kQuranAssetPath);
  return compute(parseQuran, raw);
}

Future<List<BibleBook>> loadBible() async {
  final raw = await rootBundle.loadString(kBibleAssetPath);
  return compute(parseBible, raw);
}

/// "sure:ayet" -> benzerlik listesi haritası.
Future<Map<String, List<Parallel>>> loadParallels() async {
  final raw = await rootBundle.loadString(kParallelsAssetPath);
  return compute(parseParallels, raw);
}
