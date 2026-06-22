// json_loader: assets/data altındaki JSON verilerini (temalar, tüm Kuran ve
// ayet düzeyi benzerlik indeksi) rootBundle'dan okuyup modellere çevirir.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/bible_models.dart';
import '../models/parallel.dart';
import '../models/quran_models.dart';
import '../models/theme_cluster.dart';

const String kThemesAssetPath = 'assets/data/themes.json';
const String kQuranAssetPath = 'assets/data/quran.json';
const String kBibleAssetPath = 'assets/data/bible.json';
const String kParallelsAssetPath = 'assets/data/parallels.json';

Future<List<ThemeCluster>> loadThemeClusters() async {
  final raw = await rootBundle.loadString(kThemesAssetPath);
  final decoded = json.decode(raw);
  if (decoded is! List) return const [];
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(ThemeCluster.fromJson)
      .toList();
}

Future<List<QuranSurah>> loadQuran() async {
  final raw = await rootBundle.loadString(kQuranAssetPath);
  final decoded = json.decode(raw);
  final surahs = decoded is Map<String, dynamic> ? decoded['surahs'] : decoded;
  if (surahs is! List) return const [];
  return surahs
      .whereType<Map<String, dynamic>>()
      .map(QuranSurah.fromJson)
      .toList();
}

Future<List<BibleBook>> loadBible() async {
  final raw = await rootBundle.loadString(kBibleAssetPath);
  final decoded = json.decode(raw);
  final books = decoded is Map<String, dynamic> ? decoded['books'] : decoded;
  if (books is! List) return const [];
  return books
      .whereType<Map<String, dynamic>>()
      .map(BibleBook.fromJson)
      .toList();
}

/// "sure:ayet" -> benzerlik listesi haritası.
Future<Map<String, List<Parallel>>> loadParallels() async {
  final raw = await rootBundle.loadString(kParallelsAssetPath);
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
