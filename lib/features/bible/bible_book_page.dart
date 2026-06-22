// bible_book_page: bir kitabın bölüm ızgarası. Bölüme dokununca ayetleri gösteren
// BibleChapterPage açılır.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/bible_models.dart';
import 'bible_chapter_page.dart';

class BibleBookPage extends StatelessWidget {
  final BibleBook book;

  const BibleBookPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent =
        book.role.isEmpty ? theme.colorScheme.primary : BookPalette.accent(book.role);

    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: book.chapters.length,
        itemBuilder: (context, i) {
          final chapter = book.chapters[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BibleChapterPage(book: book, chapterIndex: i),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Center(
                child: Text(
                  '${chapter.number}',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
