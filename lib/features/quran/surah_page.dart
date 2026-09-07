// surah_page: bir sûrenin ayetlerini gösterir. Her ayet: numara, Arapça metin
// (sağdan sola, Amiri), Türkçe meal, dinle/kopyala düğmeleri ve varsa diğer
// kitaplardaki benzerlikler. Kesintisiz tilavette çalan ayet vurgulanır ve
// otomatik olarak görünür kılınır.

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
  final ScrollController _scrollController = ScrollController();
  late final List<AyahRef> _queue = widget.surah.ayahs
      .map((a) => AyahRef(
            key: '${widget.surah.number}:${a.number}',
            surah: widget.surah.number,
            ayah: a.number,
          ))
      .toList();
  late final List<GlobalKey> _keys =
      List.generate(widget.surah.ayahs.length, (_) => GlobalKey());

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPlaying(String key) {
    final index = _queue.indexWhere((r) => r.key == key);
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.15,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final parallels = ref.watch(parallelsProvider).value ?? const {};
    final audio = ref.watch(audioControllerProvider);
    final prefix = '${surah.number}:';
    final thisSurahPlaying = audio.playingKey?.startsWith(prefix) ?? false;

    ref.listen(audioControllerProvider, (previous, next) {
      final message = next.error;
      if (message != null && message != previous?.error) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
      final key = next.playingKey;
      if (key != null && key != previous?.playingKey) {
        _scrollToPlaying(key);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('${surah.number}. ${surah.name}'),
        actions: [
          IconButton(
            icon: Icon(thisSurahPlaying
                ? Icons.stop_circle
                : Icons.play_circle_fill),
            tooltip:
                thisSurahPlaying ? 'Tilaveti durdur' : 'Sûreyi baştan dinle',
            onPressed: () {
              final notifier = ref.read(audioControllerProvider.notifier);
              if (thisSurahPlaying) {
                notifier.stop();
              } else {
                notifier.play(_queue, 0);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Okuma ayarları',
            onPressed: () => showReadingSettings(context),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: surah.ayahs.length,
        itemBuilder: (context, i) {
          final ayah = surah.ayahs[i];
          final key = '${surah.number}:${ayah.number}';
          return KeyedSubtree(
            key: _keys[i],
            child: _AyahTile(
              surahNumber: surah.number,
              surahName: surah.name,
              ayah: ayah,
              parallels: parallels[key] ?? const [],
              queue: _queue,
              index: i,
            ),
          );
        },
      ),
      bottomNavigationBar: thisSurahPlaying && audio.continuous
          ? _NowPlayingBar(
              label: 'Tilavet çalıyor · ${audio.playingKey}',
              onStop: () => ref.read(audioControllerProvider.notifier).stop(),
            )
          : null,
    );
  }
}

class _NowPlayingBar extends StatelessWidget {
  final String label;
  final VoidCallback onStop;

  const _NowPlayingBar({required this.label, required this.onStop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.graphic_eq, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('Durdur'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahTile extends ConsumerWidget {
  final int surahNumber;
  final String surahName;
  final QuranAyah ayah;
  final List<Parallel> parallels;
  final List<AyahRef> queue;
  final int index;

  const _AyahTile({
    required this.surahNumber,
    required this.surahName,
    required this.ayah,
    required this.parallels,
    required this.queue,
    required this.index,
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
          color: isPlaying
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPlaying
                ? theme.colorScheme.primary.withValues(alpha: 0.55)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isPlaying ? 1.5 : 1,
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
                      .play(queue, index),
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
