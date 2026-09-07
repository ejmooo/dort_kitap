// stats_page: okuma istatistikleri — günlük seri, son bir haftanın şeridi,
// iki kitaptaki ilerleme ve kaydedilen içerik sayıları. Tüm veriler cihazda.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../providers/bible_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/verse_bookmarks_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İstatistikler sıfırlansın mı?'),
        content: const Text(
          'Serin, okuma geçmişin ve ilerleme sayaçların silinir. '
          'Kaydettiğin ayetler ve favori konular etkilenmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(statsProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final bookmarks = ref.watch(verseBookmarksProvider).length;
    final favorites = ref.watch(favoritesProvider).length;
    // Bölüm toplamı veriden gelir; sabit sayı yazmak meal değişirse yanıltır.
    final totalChapters = ref.watch(bibleProvider).maybeWhen(
          data: (books) => books.fold<int>(0, (sum, b) => sum + b.chapters.length),
          orElse: () => 0,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Okuma İstatistikleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Sıfırla',
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _StreakCard(stats: stats),
          const SizedBox(height: 26),
          Text('İLERLEME', style: AppTheme.kicker(context)),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Kur’an sûreleri',
            done: stats.surahs.length,
            total: 114,
            accent: BookPalette.accent('kuran'),
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Kitab-ı Mukaddes bölümleri',
            done: stats.chapters.length,
            total: totalChapters,
            accent: BookPalette.accent('incil'),
          ),
          const SizedBox(height: 26),
          Text('BİRİKTİRDİKLERİN', style: AppTheme.kicker(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '$bookmarks',
                  label: bookmarks == 1 ? 'kayıtlı ayet' : 'kayıtlı ayet',
                  icon: Icons.bookmark,
                  accent: BookPalette.accent('zebur'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: '$favorites',
                  label: 'favori konu',
                  icon: Icons.favorite,
                  accent: BookPalette.accent('tevrat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: '${stats.totalDays}',
                  label: 'okuma günü',
                  icon: Icons.calendar_today,
                  accent: BookPalette.accent('incil'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Bir sûre veya bölüm açtığında okunmuş sayılır. Seri, arka arkaya '
            'okuma yaptığın gün sayısıdır; bir gün atlarsan sıfırdan başlar. '
            'Bu bilgilerin tamamı yalnızca bu cihazda tutulur.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final ReadingStats stats;

  const _StreakCard({required this.stats});

  static const _labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final alive = stats.streakAlive;
    final week = stats.recentDays(7);
    // Şerit bugünle biter; etiketler de bugünün gününden geriye doğru dizilir.
    final todayWeekday = DateTime.now().weekday; // 1 = Pazartesi

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(alive ? Icons.local_fire_department : Icons.ac_unit,
                  color: accent, size: 34),
              const SizedBox(width: 14),
              Text('${stats.currentStreak}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFamily: kSerifFont,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  )),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('günlük seri',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      stats.lastDay == null
                          ? 'Henüz başlamadın'
                          : alive
                              ? (stats.readToday
                                  ? 'Bugün okudun'
                                  : 'Bugün de oku, seri sürsün')
                              : 'Seri koptu — yeniden başla',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final read = week[i];
              // i = 6 bugün; geriye doğru gün adlarını kaydır.
              final weekday = (todayWeekday - (6 - i) - 1) % 7;
              return Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: read ? accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: read
                            ? accent
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: read
                        ? Icon(Icons.check,
                            size: 15, color: theme.colorScheme.onPrimary)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(_labels[weekday],
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              );
            }),
          ),
          if (stats.bestStreak > 0) ...[
            const SizedBox(height: 16),
            Text('En uzun serin: ${stats.bestStreak} gün',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final int done;
  final int total;
  final Color accent;

  const _ProgressRow({
    required this.label,
    required this.done,
    required this.total,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text(total > 0 ? '$done / $total  ·  %$percent' : '$done',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: accent.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accent;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: kSerifFont,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
