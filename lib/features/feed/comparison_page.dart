// comparison_page: bir konunun dört kitaptaki karşılığını kaydırmadan, tek ekranda
// alt alta kartlar halinde gösterir (sınıf/projeksiyon için).

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/theme_cluster.dart';
import '../../models/verse_entry.dart';
import '../../widgets/book_badge.dart';
import '../../widgets/share_helper.dart';
import '../../widgets/similarity_chip.dart';
import '../detail/source_sheet.dart';
import 'theme_page.dart' show kBookOrder;

class ComparisonPage extends StatelessWidget {
  final ThemeCluster cluster;

  const ComparisonPage({super.key, required this.cluster});

  String _shareText() {
    final buffer = StringBuffer()
      ..writeln(cluster.title)
      ..writeln(cluster.summary)
      ..writeln();
    for (final book in kBookOrder) {
      final entry = cluster.entryFor(book);
      if (entry == null) continue;
      final text = entry.text.isNotEmpty ? entry.text : entry.textEn ?? '';
      buffer
        ..writeln('• ${BookPalette.label(book)} (${entry.reference}):')
        ..writeln(text)
        ..writeln();
    }
    buffer.write('— Dört Kitap uygulaması');
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karşılaştırma'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Paylaş',
            onPressed: () => shareText(context, _shareText()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(cluster.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
          const SizedBox(height: 12),
          SimilarityChip(similarity: cluster.similarity),
          const SizedBox(height: 14),
          Text(cluster.summary,
              style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 20),
          for (final book in kBookOrder)
            _CompareCard(book: book, entry: cluster.entryFor(book)),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final String book;
  final VerseEntry? entry;

  const _CompareCard({required this.book, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = BookPalette.accent(book);
    final e = entry;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BookBadge(book: book),
              const Spacer(),
              if (e != null)
                Text(e.reference,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: accent, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          if (e == null)
            Text(
              'Bu konuda doğrudan karşılık bulunmadı.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            ..._texts(context, e),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => showSourceSheet(context, e),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Kaynak'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _texts(BuildContext context, VerseEntry e) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    if (e.hasArabic) {
      widgets.add(Directionality(
        textDirection: TextDirection.rtl,
        child: Text(e.textAr!,
            textAlign: TextAlign.right, style: AppTheme.arabic(context)),
      ));
    }
    if (e.hasTurkish) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 14));
      widgets.add(Text(e.text,
          style: theme.textTheme.titleMedium?.copyWith(height: 1.6)));
    } else if (e.hasEnglish) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 14));
      widgets.add(Text(e.textEn!,
          style: theme.textTheme.titleMedium
              ?.copyWith(height: 1.6, fontStyle: FontStyle.italic)));
      widgets.add(const SizedBox(height: 8));
      widgets.add(Text('Türkçe çeviri yakında',
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5))));
    }
    if (widgets.isEmpty) {
      widgets.add(Text('Metin bulunamadı.', style: theme.textTheme.bodyMedium));
    }
    return widgets;
  }
}
