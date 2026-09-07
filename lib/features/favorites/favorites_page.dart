// favorites_page: iki sekme — "Konular" (kaydedilen temalar) ve "Ayetler"
// (kaydedilen ayetler + kişisel notlar). Hepsi shared_preferences'ta saklanır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/saved_verse.dart';
import '../../models/theme_cluster.dart';
import '../../providers/bible_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/verse_bookmarks_provider.dart';
import '../../widgets/similarity_chip.dart';
import '../../widgets/verse_menu.dart';
import '../bible/bible_chapter_page.dart';
import '../feed/theme_page.dart';
import '../quran/surah_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favoriler'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Konular'),
              Tab(text: 'Ayetler'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ThemesTab(), _VersesTab()],
        ),
      ),
    );
  }
}

class _ThemesTab extends ConsumerWidget {
  const _ThemesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);
    final themesAsync = ref.watch(themesProvider);

    return themesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Yüklenemedi: $error')),
      data: (themes) {
        final favorites =
            themes.where((theme) => ids.contains(theme.id)).toList();
        if (favorites.isEmpty) {
          return const _Empty(
            icon: Icons.bookmark_outline,
            title: 'Henüz kayıtlı konu yok',
            message: 'Bir temanın kapağındaki yer imi simgesine dokunarak '
                'kaydedebilirsiniz.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _FavoriteTile(cluster: favorites[index]),
        );
      },
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  final ThemeCluster cluster;

  const _FavoriteTile({required this.cluster});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text(cluster.category)),
              body: ThemePage(cluster: cluster),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trUpper(cluster.category),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.bookmark),
                    color: theme.colorScheme.primary,
                    tooltip: 'Favorilerden çıkar',
                    onPressed: () =>
                        ref.read(favoritesProvider.notifier).toggle(cluster.id),
                  ),
                ],
              ),
              Text(
                cluster.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cluster.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              SimilarityChip(similarity: cluster.similarity),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersesTab extends ConsumerWidget {
  const _VersesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(verseBookmarksProvider).values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

    if (saved.isEmpty) {
      return const _Empty(
        icon: Icons.bookmark_add_outlined,
        title: 'Henüz kayıtlı ayet yok',
        message: 'Kur’an veya Kitab-ı Mukaddes okurken bir ayetin yanındaki '
            '⋮ menüsünden kaydedebilir, not ekleyebilirsiniz.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: saved.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _SavedVerseTile(verse: saved[i]),
    );
  }
}

class _SavedVerseTile extends ConsumerWidget {
  final SavedVerse verse;

  const _SavedVerseTile({required this.verse});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final parts = verse.id.split(':');
    if (verse.scripture == 'quran' && parts.length >= 2) {
      final surahNo = int.tryParse(parts[1]);
      final surahs = await ref.read(quranProvider.future);
      final match = surahs.where((s) => s.number == surahNo);
      if (match.isEmpty || !context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SurahPage(surah: match.first)),
      );
    } else if (verse.scripture == 'bible' && parts.length >= 3) {
      final bookNr = int.tryParse(parts[1]);
      final chapter = int.tryParse(parts[2]);
      final books = await ref.read(bibleProvider.future);
      final match = books.where((b) => b.nr == bookNr);
      if (match.isEmpty || !context.mounted) return;
      final book = match.first;
      final ci = book.chapters.indexWhere((c) => c.number == chapter);
      if (ci < 0) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BibleChapterPage(book: book, chapterIndex: ci),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      verse.reference,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  VerseMenu(
                    verse: verse,
                    copyText: '${verse.reference}\n\n${verse.preview}',
                  ),
                ],
              ),
              Text(
                verse.preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              if (verse.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(verse.note,
                            style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}
