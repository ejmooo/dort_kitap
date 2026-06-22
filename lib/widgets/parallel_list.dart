// ParallelList: bir ayetin diğer kitaplardaki benzer pasajlarını listeler.
// "curated" paraleller "doğrulanmış" rozetiyle, "ai" paraleller ise belirgin bir
// "yapay zeka · doğrulanmamış" uyarısıyla gösterilir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/feed/theme_page.dart';
import '../models/parallel.dart';
import '../providers/themes_provider.dart';
import 'book_badge.dart';

class ParallelList extends ConsumerWidget {
  final List<Parallel> parallels;

  const ParallelList({super.key, required this.parallels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasAi = parallels.any((p) => p.isAi);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Diğer kitaplarda benzer pasajlar',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...parallels.map((p) => _ParallelRow(parallel: p)),
          if (hasAi) ...[
            const SizedBox(height: 6),
            Text(
              '⚠ Yapay zeka önerileri doğrulanmamıştır; kaynaktan teyit ediniz.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParallelRow extends ConsumerWidget {
  final Parallel parallel;

  const _ParallelRow({required this.parallel});

  void _openTheme(BuildContext context, WidgetRef ref) {
    final id = parallel.themeId;
    if (id == null) return;
    final themes = ref.read(themesProvider).value;
    if (themes == null) return;
    final matches = themes.where((t) => t.id == id);
    if (matches.isEmpty) return;
    final cluster = matches.first;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(cluster.category)),
          body: ThemePage(cluster: cluster),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tappable = parallel.themeId != null;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookBadge(book: parallel.book),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        parallel.reference,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _OriginChip(isAi: parallel.isAi),
                  ],
                ),
                if (parallel.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    parallel.note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (tappable)
            Icon(Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
    );

    if (!tappable) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openTheme(context, ref),
      child: row,
    );
  }
}

class _OriginChip extends StatelessWidget {
  final bool isAi;

  const _OriginChip({required this.isAi});

  @override
  Widget build(BuildContext context) {
    final color = isAi ? const Color(0xFFB26A00) : const Color(0xFF2E7D32);
    final label = isAi ? 'AI · doğrulanmamış' : 'Doğrulanmış';
    final icon = isAi ? Icons.smart_toy_outlined : Icons.verified_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
