// quran_provider: tüm Kuran metnini ve ayet düzeyi benzerlik indeksini yükleyen
// FutureProvider'lar.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/json_loader.dart';
import '../models/parallel.dart';
import '../models/quran_models.dart';

final quranProvider = FutureProvider<List<QuranSurah>>((ref) {
  return loadQuran();
});

final parallelsProvider = FutureProvider<Map<String, List<Parallel>>>((ref) {
  return loadParallels();
});
