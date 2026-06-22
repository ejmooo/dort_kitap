// bible_provider: tüm Kitab-ı Mukaddes metnini (Türkçe) yükleyen FutureProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/json_loader.dart';
import '../models/bible_models.dart';

final bibleProvider = FutureProvider<List<BibleBook>>((ref) {
  return loadBible();
});
