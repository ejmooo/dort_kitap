// filter_provider: seçili kategori state'ini (null = tümü) tutan Notifier ve
// bu seçime göre temaları süzen türetilmiş provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/theme_cluster.dart';
import 'themes_provider.dart';

/// Seçili kategori; null ise filtre uygulanmaz.
class CategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? category) => state = category;
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, String?>(
  CategoryFilterNotifier.new,
);

/// Serbest metin arama sorgusu (başlık/özet/kategoride aranır).
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Kategori ve arama sorgusuna göre süzülmüş tema listesi.
final filteredThemesProvider = Provider<AsyncValue<List<ThemeCluster>>>((ref) {
  final themes = ref.watch(themesProvider);
  final category = ref.watch(categoryFilterProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  return themes.whenData((list) {
    return list.where((theme) {
      if (category != null && theme.category != category) return false;
      if (query.isEmpty) return true;
      return theme.title.toLowerCase().contains(query) ||
          theme.summary.toLowerCase().contains(query) ||
          theme.category.toLowerCase().contains(query);
    }).toList();
  });
});
