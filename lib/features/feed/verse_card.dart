// verse_card: tek bir kitabın temaya dair kartı. Referans, metin (Arapça RTL +
// Türkçe / İngilizce yedek), benzerlik etiketi ve kaynak erişimini gösterir.

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/verse_entry.dart';
import '../../widgets/book_badge.dart';
import '../../widgets/similarity_chip.dart';
import '../detail/source_sheet.dart';

class VerseCard extends StatelessWidget {
  final String book;
  final VerseEntry? entry;
  final String similarity;

  const VerseCard({
    super.key,
    required this.book,
    required this.entry,
    required this.similarity,
  });

  @override
  Widget build(BuildContext context) {
    final accent = BookPalette.accent(book);
    final theme = Theme.of(context);
    final current = entry;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: accent), // kitap sırtı (cilt motifi)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: current == null
                      ? _EmptyState(book: book)
                      : _Content(
                          entry: current,
                          accent: accent,
                          similarity: similarity,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final VerseEntry entry;
  final Color accent;
  final String similarity;

  const _Content({
    required this.entry,
    required this.accent,
    required this.similarity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BookBadge(book: entry.book, large: true),
            const Spacer(),
            SimilarityChip(similarity: similarity),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          entry.reference,
          style: theme.textTheme.titleSmall?.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _verseTexts(context, entry),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => showSourceSheet(context, entry),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text('Kaynak'),
          ),
        ),
      ],
    );
  }

  List<Widget> _verseTexts(BuildContext context, VerseEntry entry) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    if (entry.hasArabic) {
      widgets.add(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            entry.textAr!,
            textAlign: TextAlign.right,
            style: AppTheme.arabic(context),
          ),
        ),
      );
    }

    if (entry.hasTurkish) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 20));
      widgets.add(
        Text(
          entry.text,
          style: theme.textTheme.titleMedium?.copyWith(
            height: 1.7,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (entry.hasEnglish) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 20));
      widgets.add(
        Text(
          entry.textEn!,
          style: theme.textTheme.titleMedium?.copyWith(
            height: 1.7,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
      widgets.add(const SizedBox(height: 14));
      widgets.add(const _TranslationPendingNote());
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text('Metin bulunamadı.', style: theme.textTheme.bodyMedium),
      );
    }

    return widgets;
  }
}

/// Türkçe metnin (telif nedeniyle) henüz olmadığı, İngilizce gösterildiği not.
class _TranslationPendingNote extends StatelessWidget {
  const _TranslationPendingNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.translate,
            size: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Türkçe çeviri yakında',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir kitabın bu temada doğrudan karşılığı bulunmadığında gösterilir.
class _EmptyState extends StatelessWidget {
  final String book;

  const _EmptyState({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookBadge(book: book, large: true),
        const Spacer(),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 16),
              Text(
                'Bu konuda doğrudan karşılık bulunmadı.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
