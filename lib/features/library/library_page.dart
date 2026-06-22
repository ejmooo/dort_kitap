// library_page: "Oku" sekmesi. Kaldığın yere devam kartları, tam metin arama ve
// iki kutsal metni açan okuyucu kartları (Kur'an-ı Kerim, Kitab-ı Mukaddes).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../providers/bible_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/reading_progress_provider.dart';
import '../../widgets/reading_settings_sheet.dart';
import '../bible/bible_chapter_page.dart';
import '../bible/bible_page.dart';
import '../quran/quran_page.dart';
import '../quran/surah_page.dart';
import '../search/scripture_search_page.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  Future<void> _continueQuran(BuildContext context, WidgetRef ref) async {
    final surahNo = ref.read(readingProgressProvider).quranSurah;
    final surahs = await ref.read(quranProvider.future);
    final match = surahs.where((s) => s.number == surahNo);
    if (match.isEmpty || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SurahPage(surah: match.first)),
    );
  }

  Future<void> _continueBible(BuildContext context, WidgetRef ref) async {
    final progress = ref.read(readingProgressProvider);
    final books = await ref.read(bibleProvider.future);
    final match = books.where((b) => b.nr == progress.bibleBookNr);
    if (match.isEmpty || !context.mounted) return;
    final book = match.first;
    final ci = (progress.bibleChapterIndex ?? 0).clamp(0, book.chapters.length - 1);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BibleChapterPage(book: book, chapterIndex: ci),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(readingProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Metinde ara',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScriptureSearchPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Okuma ayarları',
            onPressed: () => showReadingSettings(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (progress.hasQuran || progress.hasBible) ...[
            Text('Kaldığın yerden devam',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (progress.hasQuran)
              _ContinueCard(
                label: 'Kur’an · ${progress.quranSurahName}',
                accent: BookPalette.accent('kuran'),
                onTap: () => _continueQuran(context, ref),
              ),
            if (progress.hasBible)
              _ContinueCard(
                label:
                    'Kitap · ${progress.bibleBookName} ${progress.bibleChapterNo}',
                accent: BookPalette.accent('incil'),
                onTap: () => _continueBible(context, ref),
              ),
            const SizedBox(height: 22),
          ],
          _ReaderCard(
            title: 'Kur’an-ı Kerim',
            subtitle: '114 sûre · Arapça + Türkçe meal · ayet benzerlikleri',
            icon: Icons.auto_stories,
            accent: BookPalette.accent('kuran'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuranPage()),
            ),
          ),
          const SizedBox(height: 16),
          _ReaderCard(
            title: 'Kitab-ı Mukaddes',
            subtitle: 'Eski + Yeni Ahit · 66 kitap · Türkçe (Kutsal Kitap)',
            icon: Icons.menu_book,
            accent: BookPalette.accent('incil'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BiblePage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.play_circle_outline, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _ReaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
