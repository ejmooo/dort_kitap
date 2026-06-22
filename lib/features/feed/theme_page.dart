// theme_page: bir temanın yatay PageView'ı. İlk sayfa kapak (başlık + kategori
// + özet + favori), sonraki sayfalar her kitabın kartı; altta nokta göstergesi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/theme_cluster.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/page_dots.dart';
import '../../widgets/similarity_chip.dart';
import 'comparison_page.dart';
import 'verse_card.dart';

/// Kartların kanonik (tarafsız) gösterim sırası.
const List<String> kBookOrder = ['tevrat', 'zebur', 'incil', 'kuran'];

class ThemePage extends ConsumerStatefulWidget {
  final ThemeCluster cluster;

  const ThemePage({super.key, required this.cluster});

  @override
  ConsumerState<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends ConsumerState<ThemePage> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cluster = widget.cluster;
    final pageCount = 1 + kBookOrder.length;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                _CoverCard(cluster: cluster),
                for (final book in kBookOrder)
                  VerseCard(
                    book: book,
                    entry: cluster.entryFor(book),
                    similarity: cluster.similarity,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: PageDots(count: pageCount, currentIndex: _index),
          ),
        ],
      ),
    );
  }
}

class _CoverCard extends ConsumerWidget {
  final ThemeCluster cluster;

  const _CoverCard({required this.cluster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFavorite = ref.watch(favoritesProvider).contains(cluster.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  cluster.category,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                ),
                color: isFavorite ? theme.colorScheme.primary : null,
                tooltip:
                    isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggle(cluster.id),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            cluster.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SimilarityChip(similarity: cluster.similarity),
          const SizedBox(height: 20),
          Text(
            cluster.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ComparisonPage(cluster: cluster),
              ),
            ),
            icon: const Icon(Icons.view_agenda_outlined, size: 18),
            label: const Text('Yan yana karşılaştır'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.swipe,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Kitaplar arasında geçmek için yana kaydırın',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
