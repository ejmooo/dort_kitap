// source_sheet: bir kaydın referans + kaynak bilgisini gösteren alt sayfa
// (bottom sheet). Her ayetin kaynağına UI'dan erişimi sağlar.

import 'package:flutter/material.dart';

import '../../models/verse_entry.dart';
import '../../widgets/book_badge.dart';

Future<void> showSourceSheet(BuildContext context, VerseEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => _SourceSheet(entry: entry),
  );
}

class _SourceSheet extends StatelessWidget {
  final VerseEntry entry;

  const _SourceSheet({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookBadge(book: entry.book),
            const SizedBox(height: 20),
            _Row(
              icon: Icons.tag,
              label: 'Referans',
              value: entry.reference.isEmpty ? '—' : entry.reference,
            ),
            const SizedBox(height: 16),
            _Row(
              icon: Icons.source_outlined,
              label: 'Kaynak',
              value: entry.source.isEmpty ? 'Belirtilmemiş' : entry.source,
            ),
            const SizedBox(height: 22),
            Text(
              'Metinler ilgili kamu malı veya lisanslı kaynaklardan derlenmiştir. '
              'Karşılaştırmalar tarafsız ve akademik bir çerçevede sunulur.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
