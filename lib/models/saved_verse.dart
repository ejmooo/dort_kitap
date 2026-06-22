// SavedVerse: kullanıcının kaydettiği bir ayet (Kuran veya Kitab-ı Mukaddes) ve
// üzerine yazdığı kişisel not.

class SavedVerse {
  final String id; // "quran:2:255" | "bible:1:1:1" (kitapNr:bölüm:ayet)
  final String scripture; // quran | bible
  final String reference; // görünen referans, ör. "Bakara 2:255"
  final String preview; // kısa metin
  final String note;
  final int savedAt; // epoch ms

  const SavedVerse({
    required this.id,
    required this.scripture,
    required this.reference,
    required this.preview,
    required this.note,
    required this.savedAt,
  });

  SavedVerse copyWith({String? note}) => SavedVerse(
        id: id,
        scripture: scripture,
        reference: reference,
        preview: preview,
        note: note ?? this.note,
        savedAt: savedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'scripture': scripture,
        'reference': reference,
        'preview': preview,
        'note': note,
        'savedAt': savedAt,
      };

  factory SavedVerse.fromJson(Map<String, dynamic> json) => SavedVerse(
        id: json['id'] as String? ?? '',
        scripture: json['scripture'] as String? ?? 'quran',
        reference: json['reference'] as String? ?? '',
        preview: json['preview'] as String? ?? '',
        note: json['note'] as String? ?? '',
        savedAt: json['savedAt'] as int? ?? 0,
      );
}
