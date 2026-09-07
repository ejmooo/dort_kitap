// verse_image_card: paylaşılabilir ayet görselinin tasarımı. "Mürekkep & Kâğıt"
// dilinde; kartın solunda kitap rengiyle bir cilt şeridi taşır.
//
// Renkler bilerek sabittir (açık palet). Paylaşılan görsel, gönderenin koyu tema
// tercihine göre değişmemeli — karşı taraf her zaman aynı kâğıdı görsün.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Görselin mantıksal genişliği. 3x pixelRatio ile 1080 px'e çıkar.
const double kVerseImageWidth = 360;

class VerseImageCard extends StatelessWidget {
  /// Ayet metni (meal ya da Türkçe çeviri).
  final String text;

  /// Görünen referans, ör. "Bakara 2:255".
  final String reference;

  /// Kitap kimliği: kuran | tevrat | zebur | incil.
  final String book;

  /// Varsa Arapça asıl metin (yalnızca Kur'an ayetlerinde).
  final String? arabic;

  const VerseImageCard({
    super.key,
    required this.text,
    required this.reference,
    required this.book,
    this.arabic,
  });

  static const Color _paper = Color(0xFFF5EFE3);
  static const Color _ink = Color(0xFF241F18);
  static const Color _muted = Color(0xFF6F6655);
  static const Color _brass = Color(0xFF9A6A2E);
  static const Color _hairline = Color(0xFFE0D6C2);

  /// Uzun ayetlerde yazıyı küçültür ki kart makul boyda kalsın.
  double get _bodySize {
    if (text.length > 420) return 15;
    if (text.length > 240) return 17;
    return 19;
  }

  @override
  Widget build(BuildContext context) {
    final accent = BookPalette.accent(book);

    return Container(
      width: kVerseImageWidth,
      color: _paper,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cilt: kitabın rengini taşıyan sol şerit.
            Container(width: 6, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trUpper(BookPalette.label(book)),
                      style: const TextStyle(
                        fontFamily: kLatinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (arabic != null && arabic!.isNotEmpty) ...[
                      Text(
                        arabic!,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: kArabicFont,
                          fontSize: 22,
                          height: 1.95,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontFamily: kSerifFont,
                        fontSize: _bodySize,
                        height: 1.62,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(height: 1, color: _hairline),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reference,
                            style: const TextStyle(
                              fontFamily: kLatinFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ),
                        Text(
                          'DÖRT KİTAP',
                          style: const TextStyle(
                            fontFamily: kLatinFont,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: _brass,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
