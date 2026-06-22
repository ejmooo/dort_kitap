// verse_menu: bir ayet için seçenek menüsü (kopyala · kaydet/kaldır · not).
// Hem Kuran hem Kitab-ı Mukaddes okuyucularında kullanılır.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_verse.dart';
import '../providers/verse_bookmarks_provider.dart';
import 'share_helper.dart';

class VerseMenu extends ConsumerWidget {
  final SavedVerse verse;
  final String copyText;

  const VerseMenu({super.key, required this.verse, required this.copyText});

  SavedVerse _stamped() => SavedVerse(
        id: verse.id,
        scripture: verse.scripture,
        reference: verse.reference,
        preview: verse.preview,
        note: verse.note,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      );

  Future<void> _handle(
      BuildContext context, WidgetRef ref, String action, bool saved) async {
    final notifier = ref.read(verseBookmarksProvider.notifier);
    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: copyText));
        if (context.mounted) _toast(context, 'Panoya kopyalandı');
      case 'share':
        if (context.mounted) await shareText(context, copyText);
      case 'save':
        await notifier.toggle(_stamped());
        if (context.mounted) {
          _toast(context, saved ? 'Kayıt kaldırıldı' : 'Ayet kaydedildi');
        }
      case 'note':
        if (!saved) await notifier.save(_stamped());
        if (context.mounted) await _editNote(context, ref);
    }
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref) async {
    final current = ref.read(verseBookmarksProvider)[verse.id]?.note ?? '';
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notunuz'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Bu ayet hakkında kişisel notunuz…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref.read(verseBookmarksProvider.notifier)
          .setNote(verse.id, result.trim());
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final saved = ref.watch(verseBookmarksProvider).containsKey(verse.id);
    return PopupMenuButton<String>(
      tooltip: 'Seçenekler',
      icon: Icon(
        saved ? Icons.bookmark : Icons.more_vert,
        size: 20,
        color: saved
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onSelected: (action) => _handle(context, ref, action, saved),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'copy',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.copy_outlined),
            title: Text('Kopyala'),
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.ios_share),
            title: Text('Paylaş'),
          ),
        ),
        PopupMenuItem(
          value: 'save',
          child: ListTile(
            dense: true,
            leading: Icon(saved ? Icons.bookmark_remove : Icons.bookmark_add),
            title: Text(saved ? 'Kaydı kaldır' : 'Kaydet'),
          ),
        ),
        PopupMenuItem(
          value: 'note',
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.edit_note),
            title: Text(saved ? 'Notu düzenle' : 'Not ekle'),
          ),
        ),
      ],
    );
  }
}
