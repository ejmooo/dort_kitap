// themes_provider: themes.json'dan tema kümelerini yükleyen FutureProvider ve
// mevcut kategorileri türeten yardımcı provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/json_loader.dart';
import '../models/theme_cluster.dart';

/// Tüm tema kümelerini lokal asset'ten asenkron yükler.
final themesProvider = FutureProvider<List<ThemeCluster>>((ref) {
  return loadThemeClusters();
});

/// Yüklenen temalardan benzersiz, sıralı kategori listesi üretir.
final categoriesProvider = Provider<List<String>>((ref) {
  final themes = ref.watch(themesProvider);
  return themes.maybeWhen(
    data: (list) {
      final set = <String>{for (final theme in list) theme.category};
      final sorted = set.toList()..sort();
      return sorted;
    },
    orElse: () => const <String>[],
  );
});
