// scripture_search_page: Kur'an meali ve Kitab-ı Mukaddes metninde tam metin arama.
// Sonuca dokununca ilgili sûre/bölüm açılır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bible_models.dart';
import '../../models/quran_models.dart';
import '../../providers/bible_provider.dart';
import '../../providers/quran_provider.dart';
import '../bible/bible_chapter_page.dart';
import '../quran/surah_page.dart';

enum _Scope { all, quran, bible }

class _Hit {
  final String reference;
  final String text;
  final QuranSurah? surah;
  final BibleBook? book;
  final int? chapterIndex;

  const _Hit({
    required this.reference,
    required this.text,
    this.surah,
    this.book,
    this.chapterIndex,
  });
}

const int _maxHits = 200;

class ScriptureSearchPage extends ConsumerStatefulWidget {
  const ScriptureSearchPage({super.key});

  @override
  ConsumerState<ScriptureSearchPage> createState() =>
      _ScriptureSearchPageState();
}

class _ScriptureSearchPageState extends ConsumerState<ScriptureSearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  _Scope _scope = _Scope.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Hit> _search(List<QuranSurah> quran, List<BibleBook> bible) {
    final q = _query.trim().toLowerCase();
    final hits = <_Hit>[];
    if (q.length < 2) return hits;

    if (_scope != _Scope.bible) {
      for (final surah in quran) {
        for (final ayah in surah.ayahs) {
          if (ayah.turkish.toLowerCase().contains(q)) {
            hits.add(_Hit(
              reference: '${surah.name} ${surah.number}:${ayah.number}',
              text: ayah.turkish,
              surah: surah,
            ));
            if (hits.length >= _maxHits) return hits;
          }
        }
      }
    }
    if (_scope != _Scope.quran) {
      for (final book in bible) {
        for (var ci = 0; ci < book.chapters.length; ci++) {
          final chapter = book.chapters[ci];
          for (final verse in chapter.verses) {
            if (verse.text.toLowerCase().contains(q)) {
              hits.add(_Hit(
                reference: '${book.name} ${chapter.number}:${verse.number}',
                text: verse.text,
                book: book,
                chapterIndex: ci,
              ));
              if (hits.length >= _maxHits) return hits;
            }
          }
        }
      }
    }
    return hits;
  }

  void _open(_Hit hit) {
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
    final quran = ref.watch(quranProvider);
    final bible = ref.watch(bibleProvider);
    final loading = quran.isLoading || bible.isLoading;

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
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _results(quran.value ?? const [], bible.value ?? const []),
          ),
        ],
      ),
    );
  }

  Widget _results(List<QuranSurah> quran, List<BibleBook> bible) {
    if (_query.trim().length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Aramak için en az 2 karakter yazın.',
              textAlign: TextAlign.center),
        ),
      );
    }
    final hits = _search(quran, bible);
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
