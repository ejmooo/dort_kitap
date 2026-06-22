// VerseEntry: tek bir kitaba ait ayet/pasaj kaydı (referans, metinler, kaynak).
// Türkçe (text), Arapça (text_ar) ve İngilizce kamu malı (text_en) alanlarını tutar.

class VerseEntry {
  final String book; // tevrat | zebur | incil | kuran
  final String reference;
  final String text; // Türkçe metin (boş olabilir)
  final String? textAr; // Arapça (genelde Kuran)
  final String? textEn; // İngilizce kamu malı (Bible için yedek)
  final String source;

  const VerseEntry({
    required this.book,
    required this.reference,
    required this.text,
    required this.source,
    this.textAr,
    this.textEn,
  });

  factory VerseEntry.fromJson(Map<String, dynamic> json) {
    return VerseEntry(
      book: json['book'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      text: json['text'] as String? ?? '',
      textAr: _clean(json['text_ar']),
      textEn: _clean(json['text_en']),
      source: json['source'] as String? ?? '',
    );
  }

  /// Boş/whitespace stringleri null'a indirger.
  static String? _clean(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get hasTurkish => text.trim().isNotEmpty;
  bool get hasArabic => textAr != null;
  bool get hasEnglish => textEn != null;
}
