// ThemeCluster: küratörlü bir tema kümesi (başlık, kategori, benzerlik, özet)
// ve o temaya ait kitap kayıtlarının (VerseEntry) listesini temsil eder.

import 'verse_entry.dart';

class ThemeCluster {
  final String id;
  final String title;
  final String category;
  final String similarity; // identical | near_identical | thematic
  final String summary;
  final List<VerseEntry> entries;

  const ThemeCluster({
    required this.id,
    required this.title,
    required this.category,
    required this.similarity,
    required this.summary,
    required this.entries,
  });

  factory ThemeCluster.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const [];
    return ThemeCluster(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      similarity: json['similarity'] as String? ?? 'thematic',
      summary: json['summary'] as String? ?? '',
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(VerseEntry.fromJson)
          .toList(),
    );
  }

  /// İlgili kitabın kaydını döndürür; yoksa null (UI "karşılık yok" gösterir).
  VerseEntry? entryFor(String book) {
    for (final entry in entries) {
      if (entry.book == book) return entry;
    }
    return null;
  }
}
