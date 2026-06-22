// Kitab-ı Mukaddes okuyucu modelleri: kitap > bölüm > ayet (Türkçe).

class BibleVerse {
  final int number;
  final String text;

  const BibleVerse({required this.number, required this.text});

  factory BibleVerse.fromJson(Map<String, dynamic> json) => BibleVerse(
        number: json['n'] as int? ?? 0,
        text: json['tr'] as String? ?? '',
      );
}

class BibleChapter {
  final int number;
  final List<BibleVerse> verses;

  const BibleChapter({required this.number, required this.verses});

  factory BibleChapter.fromJson(Map<String, dynamic> json) {
    final raw = json['verses'] as List<dynamic>? ?? const [];
    return BibleChapter(
      number: json['n'] as int? ?? 0,
      verses:
          raw.whereType<Map<String, dynamic>>().map(BibleVerse.fromJson).toList(),
    );
  }
}

class BibleBook {
  final int nr;
  final String name;
  final String testament; // eski | yeni
  final String role; // tevrat | zebur | incil | ''
  final int chapterCount;
  final List<BibleChapter> chapters;

  const BibleBook({
    required this.nr,
    required this.name,
    required this.testament,
    required this.role,
    required this.chapterCount,
    required this.chapters,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    final raw = json['chapters'] as List<dynamic>? ?? const [];
    return BibleBook(
      nr: json['nr'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      testament: json['testament'] as String? ?? 'eski',
      role: json['role'] as String? ?? '',
      chapterCount: json['chapterCount'] as int? ?? raw.length,
      chapters: raw
          .whereType<Map<String, dynamic>>()
          .map(BibleChapter.fromJson)
          .toList(),
    );
  }
}
