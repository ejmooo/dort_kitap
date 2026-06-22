// surah_page: bir sûrenin ayetlerini gösterir. Her ayet: numara, Arapça metin
// (sağdan sola, Amiri), Türkçe meal, kopyala düğmesi ve varsa diğer kitaplardaki
// benzerlikler.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/parallel.dart';
import '../../models/quran_models.dart';
import '../../models/saved_verse.dart';
import '../../providers/audio_provider.dart';
import '../../providers/quran_provider.dart';
import '../../providers/reading_progress_provider.dart';
import '../../widgets/parallel_list.dart';
import '../../widgets/reading_settings_sheet.dart';
import '../../widgets/verse_menu.dart';

class SurahPage extends ConsumerStatefulWidget {
  final QuranSurah surah;

  const SurahPage({super.key, required this.surah});

  @override
  ConsumerState<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends ConsumerState<SurahPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(readingProgressProvider.notifier)
          .setQuran(widget.surah.number, widget.surah.name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final parallels = ref.watch(parallelsProvider).value ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text('${surah.number}. ${surah.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Okuma ayarları',
            onPressed: () => showReadingSettings(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: surah.ayahs.length,
        itemBuilder: (context, i) {
          final ayah = surah.ayahs[i];
          final key = '${surah.number}:${ayah.number}';
          return _AyahTile(
            surahNumber: surah.number,
            surahName: surah.name,
            ayah: ayah,
            parallels: parallels[key] ?? const [],
          );
        },
      ),
    );
  }
}

class _AyahTile extends ConsumerWidget {
  final int surahNumber;
  final String surahName;
  final QuranAyah ayah;
  final List<Parallel> parallels;

  const _AyahTile({
    required this.surahNumber,
    required this.surahName,
    required this.ayah,
    required this.parallels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final key = '$surahNumber:${ayah.number}';
    final audio = ref.watch(audioControllerProvider);
    final isPlaying = audio.playingKey == key;
    final isLoading = isPlaying && audio.loading;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$surahNumber:${ayah.number}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                if (parallels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.compare_arrows,
                        size: 16,
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.7)),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: isPlaying ? 'Durdur' : 'Dinle',
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline,
                          color: isPlaying ? theme.colorScheme.primary : null,
                        ),
                  onPressed: () => ref
                      .read(audioControllerProvider.notifier)
                      .toggle(key, ayah.global),
                ),
                VerseMenu(
                  verse: SavedVerse(
                    id: 'quran:$surahNumber:${ayah.number}',
                    scripture: 'quran',
                    reference: '$surahName $surahNumber:${ayah.number}',
                    preview: ayah.turkish,
                    note: '',
                    savedAt: 0,
                  ),
                  copyText: '$surahName $surahNumber:${ayah.number}\n\n'
                      '${ayah.arabic}\n\n${ayah.turkish}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                ayah.arabic,
                textAlign: TextAlign.right,
                style: AppTheme.arabic(context),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              ayah.turkish,
              style: theme.textTheme.titleMedium?.copyWith(height: 1.7),
            ),
            if (parallels.isNotEmpty) ParallelList(parallels: parallels),
          ],
        ),
      ),
    );
  }
}
