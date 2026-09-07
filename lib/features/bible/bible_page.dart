// bible_page: Kitab-ı Mukaddes kitap listesi (Eski/Yeni Ahit), aranabilir.
// Bir kitaba dokununca bölüm ızgarası (BibleBookPage) açılır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/bible_models.dart';
import '../../providers/bible_provider.dart';
import 'bible_book_page.dart';

class BiblePage extends ConsumerStatefulWidget {
  const BiblePage({super.key});

  @override
  ConsumerState<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends ConsumerState<BiblePage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bible = ref.watch(bibleProvider);
    final q = _query.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Kitab-ı Mukaddes')),
      body: bible.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Yüklenemedi: $error')),
        data: (books) {
          final filtered = q.isEmpty
              ? books
              : books
                  .where((b) =>
                      b.name.toLowerCase().contains(q) || b.nr.toString() == q)
                  .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  controller: _controller,
                  hintText: 'Kitap ara (ör. Yaratılış, Mezmurlar)',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Sonuç bulunamadı.'))
                    : _BookList(books: filtered, grouped: q.isEmpty),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final List<BibleBook> books;
  final bool grouped;

  const _BookList({required this.books, required this.grouped});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    String? lastTestament;
    for (final book in books) {
      if (grouped && book.testament != lastTestament) {
        lastTestament = book.testament;
        children.add(_Header(
            label: book.testament == 'eski' ? 'Eski Ahit' : 'Yeni Ahit'));
      }
      children.add(_BookTile(book: book));
    }
    return ListView(children: children);
  }
}

class _Header extends StatelessWidget {
  final String label;
  const _Header({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(
        trUpper(label),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BibleBook book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = book.role.isEmpty
        ? theme.colorScheme.primary
        : BookPalette.accent(book.role);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.12),
        foregroundColor: accent,
        child: Text('${book.nr}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
      title: Text(book.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${book.chapterCount} bölüm'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BibleBookPage(book: book)),
      ),
    );
  }
}
