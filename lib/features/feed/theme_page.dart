import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/theme_cluster.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/atlas_motion.dart';
import '../../widgets/similarity_chip.dart';
import 'comparison_page.dart';
import 'verse_card.dart';

/// Equal, canonical ordering across every topic.
const List<String> kBookOrder = ['tevrat', 'zebur', 'incil', 'kuran'];

class ThemePage extends ConsumerStatefulWidget {
  final ThemeCluster cluster;
  const ThemePage({super.key, required this.cluster});
  @override
  ConsumerState<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends ConsumerState<ThemePage> {
  final _controller = PageController();
  int _index = 0;
  final _tabKeys = List.generate(5, (_) => GlobalKey());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) => AtlasMotion.goToPage(context, _controller, index);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (index) {
              AtlasMotion.selection();
              setState(() => _index = index);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final tabContext = _tabKeys[index].currentContext;
                if (tabContext != null) {
                  Scrollable.ensureVisible(
                    tabContext,
                    alignment: .5,
                    duration: AtlasMotion.duration(context),
                  );
                }
              });
            },
            children: [
              _CoverCard(cluster: widget.cluster, onRead: () => _goTo(1)),
              for (final book in kBookOrder)
                VerseCard(
                  book: book,
                  entry: widget.cluster.entryFor(book),
                  similarity: widget.cluster.similarity,
                ),
            ],
          ),
        ),
        SizedBox(
          height: 58,
          child: SingleChildScrollView(
            key: const ValueKey('book-tabs'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                for (var index = 0; index < 5; index++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Semantics(
                      key: _tabKeys[index],
                      selected: index == _index,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: index == _index
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                          backgroundColor: index == _index
                              ? colors.primary
                              : colors.surfaceContainerLow,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(48, 48),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () => _goTo(index),
                        child: Text(
                          index == 0
                              ? 'Genel bakış'
                              : BookPalette.label(kBookOrder[index - 1]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverCard extends ConsumerWidget {
  const _CoverCard({required this.cluster, required this.onRead});
  final ThemeCluster cluster;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((saved) => saved.contains(cluster.id)),
    );
    final text = Theme.of(context).textTheme;
    const cream = Color(0xFFF8F3E6);
    const muted = Color(0xFFBDCEC4);
    void toggleFavorite() {
      AtlasMotion.selection();
      ref.read(favoritesProvider.notifier).toggle(cluster.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? 'Konu favorilerden çıkarıldı'
                : 'Konu favorilere eklendi',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF244B40), Color(0xFF112E27)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF163B30).withValues(alpha: .12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DÖRT SES.\nORTAK BİR KEŞİF.',
                                  style: AppTheme.kicker(
                                    context,
                                    color: muted,
                                  ).copyWith(height: 1.7, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const AtlasMark(size: 64),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: isFavorite
                                ? 'Favorilerden çıkar'
                                : 'Favorilere ekle',
                            style: IconButton.styleFrom(
                              backgroundColor: cream.withValues(alpha: .1),
                              foregroundColor: cream,
                            ),
                            onPressed: toggleFavorite,
                            icon: AnimatedSwitcher(
                              duration: AtlasMotion.duration(context, 180),
                              child: Icon(
                                isFavorite
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                key: ValueKey(isFavorite),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        trUpper(cluster.category),
                        style: AppTheme.kicker(
                          context,
                          color: const Color(0xFFF2BF91),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        cluster.title,
                        style: text.displaySmall?.copyWith(
                          color: cream,
                          height: 1.13,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        cluster.summary,
                        style: text.bodyMedium?.copyWith(
                          color: muted,
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Theme(
                        data: AppTheme.dark(),
                        child: SimilarityChip(similarity: cluster.similarity),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF2BF91),
                              foregroundColor: const Color(0xFF17392F),
                              minimumSize: const Size(0, 48),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: onRead,
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: const Text('Oku'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cream,
                              side: const BorderSide(color: Color(0xFF78958A)),
                              minimumSize: const Size(0, 48),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ComparisonPage(cluster: cluster),
                              ),
                            ),
                            icon: const Icon(
                              Icons.view_week_outlined,
                              size: 18,
                            ),
                            label: const Text('Karşılaştır'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
