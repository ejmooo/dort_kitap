// theme_page: bir temanın yatay PageView'ı. İlk sayfa kapak (başlık + kategori
// + özet + favori), sonraki sayfalar her kitabın kartı; altta nokta göstergesi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
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
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trUpper(cluster.category),
                        style: AppTheme.kicker(context,
                            color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    Container(
                        width: 38,
                        height: 2,
                        color: theme.colorScheme.primary),
                  ],
                ),
              ),
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
          const SizedBox(height: 18),
          Text(
            cluster.title,
            style: theme.textTheme.displaySmall?.copyWith(height: 1.15),
          ),
          const SizedBox(height: 18),
          SimilarityChip(similarity: cluster.similarity),
          const SizedBox(height: 20),
          Text(
            cluster.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.65,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 24),
          _TraditionDots(cluster: cluster),
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

/// Dört geleneği temsil eden imza motif: her kitap aksan rengiyle bir nokta;
/// o temada karşılığı varsa dolu, yoksa içi boş.
class _TraditionDots extends StatelessWidget {
  final ThemeCluster cluster;

  const _TraditionDots({required this.cluster});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        for (final book in kBookOrder)
          _dot(theme, book, cluster.entryFor(book) != null),
      ],
    );
  }

  Widget _dot(ThemeData theme, String book, bool present) {
    final color = BookPalette.accent(book);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: present ? color : Colors.transparent,
            border: Border.all(color: color, width: 1.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          BookPalette.label(book),
          style: theme.textTheme.labelMedium?.copyWith(
            color: present
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontWeight: present ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
