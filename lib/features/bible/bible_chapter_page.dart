// bible_chapter_page: bir bölümün ayetlerini Türkçe gösterir. Her ayette kopyala/
// kaydet/not menüsü, varsa Kur'an'daki benzer ayetler; altta bölüm gezinmesi.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/bible_models.dart';
import '../../models/parallel.dart';
import '../../models/saved_verse.dart';
import '../../providers/bible_parallels_provider.dart';
import '../../providers/reading_progress_provider.dart';
import '../../widgets/parallel_list.dart';
import '../../widgets/reading_settings_sheet.dart';
import '../../widgets/verse_menu.dart';

class BibleChapterPage extends ConsumerStatefulWidget {
  final BibleBook book;
  final int chapterIndex;

  const BibleChapterPage({
    super.key,
    required this.book,
    required this.chapterIndex,
  });

  @override
  ConsumerState<BibleChapterPage> createState() => _BibleChapterPageState();
}

class _BibleChapterPageState extends ConsumerState<BibleChapterPage> {
  late int _index = widget.chapterIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  void _record() {
    if (!mounted) return;
    final book = widget.book;
    ref.read(readingProgressProvider.notifier).setBible(
          book.nr,
          book.name,
          _index,
          book.chapters[_index].number,
        );
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _record();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = widget.book;
    final chapter = book.chapters[_index];
    final accent =
        book.role.isEmpty ? theme.colorScheme.primary : BookPalette.accent(book.role);

    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name} ${chapter.number}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Okuma ayarları',
            onPressed: () => showReadingSettings(context),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        final reverseParallels =
            ref.watch(bibleParallelsProvider).value ?? const {};
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chapter.verses.length,
          itemBuilder: (context, i) {
            final verse = chapter.verses[i];
            final key = '${book.nr}:${chapter.number}:${verse.number}';
            return _VerseTile(
              book: book,
              chapter: chapter,
              verse: verse,
              accent: accent,
              parallels: reverseParallels[key] ?? const [],
            );
          },
        );
      }),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Önceki'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _index < book.chapters.length - 1
                      ? () => _goTo(_index + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Sonraki'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  final BibleBook book;
  final BibleChapter chapter;
  final BibleVerse verse;
  final Color accent;
  final List<Parallel> parallels;

  const _VerseTile({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.accent,
    required this.parallels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = '${book.name} ${chapter.number}:${verse.number}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3, right: 12),
            width: 26,
            alignment: Alignment.center,
            child: Text(
              '${verse.number}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: accent, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verse.text,
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.6),
                  ),
                  if (parallels.isNotEmpty)
                    ParallelList(parallels: parallels),
                ],
              ),
            ),
          ),
          VerseMenu(
            verse: SavedVerse(
              id: 'bible:${book.nr}:${chapter.number}:${verse.number}',
              scripture: 'bible',
              reference: reference,
              preview: verse.text,
              note: '',
              savedAt: 0,
            ),
            copyText: '$reference\n\n${verse.text}',
          ),
        ],
      ),
    );
  }
}
