// Parallel: bir Kuran ayetinin diğer kitaplardaki benzer pasaj önerisi.
// origin "curated" (kaynaklı/doğrulanmış) veya "ai" (yapay zeka, doğrulanmamış) olur.

class Parallel {
  final String book; // tevrat | zebur | incil
  final String reference;
  final String note;
  final String origin; // curated | ai
  final String? themeId; // küratörlü ise ilgili tema

  const Parallel({
    required this.book,
    required this.reference,
    required this.note,
    required this.origin,
    this.themeId,
  });

  bool get isAi => origin == 'ai';

  factory Parallel.fromJson(Map<String, dynamic> json) {
    return Parallel(
      book: json['book'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      note: json['note'] as String? ?? '',
      origin: json['origin'] as String? ?? 'ai',
      themeId: json['themeId'] as String?,
    );
  }
}
