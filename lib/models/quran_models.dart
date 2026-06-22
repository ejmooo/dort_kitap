// Kuran okuyucu veri modelleri: sûre ve ayet (Arapça + Türkçe meal).

class QuranAyah {
  final int number; // sûre içindeki ayet numarası
  final int global; // Kuran genelinde 1..6236 (ses CDN'i için)
  final String arabic;
  final String turkish;

  const QuranAyah({
    required this.number,
    required this.global,
    required this.arabic,
    required this.turkish,
  });

  factory QuranAyah.fromJson(Map<String, dynamic> json) {
    return QuranAyah(
      number: json['n'] as int? ?? 0,
      global: json['g'] as int? ?? 0,
      arabic: json['ar'] as String? ?? '',
      turkish: json['tr'] as String? ?? '',
    );
  }
}

class QuranSurah {
  final int number;
  final String name;
  final int ayahCount;
  final List<QuranAyah> ayahs;

  const QuranSurah({
    required this.number,
    required this.name,
    required this.ayahCount,
    required this.ayahs,
  });

  factory QuranSurah.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'] as List<dynamic>? ?? const [];
    return QuranSurah(
      number: json['number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      ayahCount: json['ayahCount'] as int? ?? rawAyahs.length,
      ayahs: rawAyahs
          .whereType<Map<String, dynamic>>()
          .map(QuranAyah.fromJson)
          .toList(),
    );
  }
}
