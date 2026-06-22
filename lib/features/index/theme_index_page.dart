// theme_index_page: tüm temaları kategorilere göre taranabilir liste. Bir temaya
// dokununca tema açılır; kategori başlığındaki düğme o kategoriyi sunum olarak başlatır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/theme_cluster.dart';
import '../../providers/themes_provider.dart';
import '../../widgets/similarity_chip.dart';
import '../feed/theme_page.dart';
import '../presentation/presentation_page.dart';

class ThemeIndexPage extends ConsumerWidget {
  const ThemeIndexPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(themesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema Dizini'),
        actions: [
          themesAsync.maybeWhen(
            data: (themes) => IconButton(
              icon: const Icon(Icons.slideshow),
              tooltip: 'Tümünü sunum olarak başlat',
              onPressed: themes.isEmpty
                  ? null
                  : () => _present(context, themes),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: themesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Yüklenemedi: $error')),
        data: (themes) {
          final grouped = <String, List<ThemeCluster>>{};
          for (final t in themes) {
            grouped.putIfAbsent(t.category, () => []).add(t);
          }
          final categories = grouped.keys.toList()..sort();

          return ListView(
            children: [
              for (final category in categories) ...[
                _CategoryHeader(
                  category: category,
                  count: grouped[category]!.length,
                  onPresent: () => _present(context, grouped[category]!),
                ),
                ...grouped[category]!.map((t) => _ThemeRow(cluster: t)),
              ],
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  void _present(BuildContext context, List<ThemeCluster> themes) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PresentationPage(themes: themes)),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onPresent;

  const _CategoryHeader({
    required this.category,
    required this.count,
    required this.onPresent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${category.toUpperCase()}  ·  $count',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.slideshow_outlined),
            tooltip: 'Bu kategoriyi sun',
            onPressed: onPresent,
          ),
        ],
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final ThemeCluster cluster;

  const _ThemeRow({required this.cluster});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(cluster.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        cluster.summary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
      ),
      trailing: SimilarityChip(similarity: cluster.similarity),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(cluster.category)),
            body: ThemePage(cluster: cluster),
          ),
        ),
      ),
    );
  }
}
