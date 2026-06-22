// app_theme: açık/koyu tema tanımları, kitaplara özgü aksan renkleri ve
// tipografi (Latin için Manrope, Arapça için Amiri) yardımcılarını içerir.

import 'package:flutter/material.dart';

/// Uygulama geneli yazı tipi aileleri (assets/fonts'tan, çevrimdışı).
const String kLatinFont = 'Manrope';
const String kArabicFont = 'Amiri';

/// Kitap kimliklerine göre aksan rengi ve okunabilir etiket sağlar.
class BookPalette {
  const BookPalette._();

  static const Map<String, Color> _accents = {
    'tevrat': Color(0xFF3B6EA5), // sakin mavi
    'zebur': Color(0xFF8E6BAA), // muted mor
    'incil': Color(0xFF2F8F83), // teal
    'kuran': Color(0xFF4F8A3D), // adaçayı yeşili
  };

  static const Map<String, String> _labels = {
    'tevrat': 'Tevrat',
    'zebur': 'Zebur',
    'incil': 'İncil',
    'kuran': 'Kuran',
  };

  static Color accent(String book) => _accents[book] ?? const Color(0xFF6B7280);

  static String label(String book) => _labels[book] ?? book;
}

class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF4F8A3D);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: kLatinFont,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
    );
  }

  /// Arapça metinler için Amiri tabanlı, satır aralığı geniş stil.
  static TextStyle arabic(BuildContext context, {double fontSize = 28}) {
    return TextStyle(
      fontFamily: kArabicFont,
      fontSize: fontSize,
      height: 1.9,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
