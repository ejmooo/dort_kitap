// scripture_search_page: Kur'an meali ve Kitab-ı Mukaddes metninde tam metin arama.
// Önceden hazırlanmış küçük-harf dizini (searchIndexProvider) üzerinde, 300 ms
// debounce ile tarar. Sonuca dokununca ilgili sûre/bölüm açılır.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/search_provider.dart';
import '../bible/bible_chapter_page.dart';
import '../quran/surah_page.dart';

enum _Scope { all, quran, bible }

const int _maxHits = 200;
const Duration _debounce = Duration(milliseconds: 300);

class ScriptureSearchPage extends ConsumerStatefulWidget {
  const ScriptureSearchPage({super.key});

  @override
  ConsumerState<ScriptureSearchPage> createState() =>
      _ScriptureSearchPageState();
}

class _ScriptureSearchPageState extends ConsumerState<ScriptureSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  _Scope _scope = _Scope.all;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _clear() {
    _debounceTimer?.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  List<SearchEntry> _search(List<SearchEntry> index) {
    final q = _query.trim().toLowerCase();
    final hits = <SearchEntry>[];
    if (q.length < 2) return hits;
    for (final entry in index) {
      if (_scope == _Scope.quran && !entry.isQuran) continue;
      if (_scope == _Scope.bible && entry.isQuran) continue;
      if (entry.lower.contains(q)) {
        hits.add(entry);
        if (hits.length >= _maxHits) break;
      }
    }
    return hits;
  }

  void _open(SearchEntry hit) {
    if (hit.surah != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SurahPage(surah: hit.surah!)),
      );
    } else if (hit.book != null && hit.chapterIndex != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              BibleChapterPage(book: hit.book!, chapterIndex: hit.chapterIndex!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(searchIndexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Metinde ara')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _controller,
              hintText: 'Bir kelime/ifade yazın (ör. sabır)',
              leading: const Icon(Icons.search),
              trailing: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clear,
                  ),
              ],
              onChanged: _onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<_Scope>(
              segments: const [
                ButtonSegment(value: _Scope.all, label: Text('Tümü')),
                ButtonSegment(value: _Scope.quran, label: Text('Kur’an')),
                ButtonSegment(value: _Scope.bible, label: Text('Kitap')),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => setState(() => _scope = s.first),
            ),
          ),
          Expanded(
            child: index.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Yüklenemedi: $error')),
              data: _results,
            ),
          ),
        ],
      ),
    );
  }

  Widget _results(List<SearchEntry> index) {
    if (_query.trim().length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Aramak için en az 2 karakter yazın.',
              textAlign: TextAlign.center),
        ),
      );
    }
    final hits = _search(index);
    if (hits.isEmpty) {
      return const Center(child: Text('Sonuç bulunamadı.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            hits.length >= _maxHits
                ? 'İlk $_maxHits sonuç gösteriliyor'
                : '${hits.length} sonuç',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: hits.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final hit = hits[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                title: Text(hit.reference,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary)),
                subtitle: Text(hit.text,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => _open(hit),
              );
            },
          ),
        ),
      ],
    );
  }
}
