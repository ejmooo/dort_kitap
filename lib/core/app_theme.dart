// app_theme: "Mürekkep & Kâğıt" tasarım dili. Sıcak kâğıt zemini, mürekkep tonu
// metin, pirinç/altın vurgu; başlıklarda serif (Lora), gövdede Manrope, Arapça'da
// Amiri. Material varsayılanı yerine elle kurulmuş, editöryel bir kimlik.

import 'package:flutter/material.dart';

/// Yazı tipi aileleri (assets/fonts'tan, çevrimdışı).
const String kLatinFont = 'Manrope'; // gövde/arayüz
const String kSerifFont = 'Lora'; // başlıklar — editöryel karakter
const String kArabicFont = 'Amiri'; // Arapça metin

/// Türkçe'ye duyarlı büyük harf: Dart'ın toUpperCase'i i→I yaptığı için
/// (İ kaybolur) önce i→İ ve ı→I dönüşümü uygulanır.
String trUpper(String text) =>
    text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Kitap kimliklerine göre aksan rengi (sıcak paletle uyumlu, mücevher/toprak
/// tonları) ve okunabilir etiket sağlar.
class BookPalette {
  const BookPalette._();

  static const Map<String, Color> _accents = {
    'tevrat': Color(0xFF3E5C8A), // derin çivit mavisi
    'zebur': Color(0xFF7E5A86), // erik moru
    'incil': Color(0xFF2F7E73), // teal-yeşil
    'kuran': Color(0xFF5C7A36), // zeytin yeşili
  };

  static const Map<String, String> _labels = {
    'tevrat': 'Tevrat',
    'zebur': 'Zebur',
    'incil': 'İncil',
    'kuran': 'Kuran',
  };

  static Color accent(String book) => _accents[book] ?? const Color(0xFF6B6253);

  static String label(String book) => _labels[book] ?? book;
}

class AppTheme {
  const AppTheme._();

  // Pirinç/altın marka vurgusu.
  static const Color _brass = Color(0xFF9A6A2E);
  static const Color _gold = Color(0xFFD2A862);

  static final ColorScheme _light = const ColorScheme(
    brightness: Brightness.light,
    primary: _brass,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF0DFC4),
    onPrimaryContainer: Color(0xFF553811),
    secondary: Color(0xFF6F6655),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEAE0CD),
    onSecondaryContainer: Color(0xFF3D3729),
    tertiary: Color(0xFF2F7E73),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCFE9E2),
    onTertiaryContainer: Color(0xFF12302B),
    error: Color(0xFFA63B2E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF6D9D3),
    onErrorContainer: Color(0xFF410E07),
    surface: Color(0xFFF5EFE3), // kâğıt
    onSurface: Color(0xFF241F18), // mürekkep
    onSurfaceVariant: Color(0xFF6F6655),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFBF6EC),
    surfaceContainer: Color(0xFFF1EADC),
    surfaceContainerHigh: Color(0xFFEBE2D0),
    surfaceContainerHighest: Color(0xFFE5DBC6),
    outline: Color(0xFFB7AB94),
    outlineVariant: Color(0xFFE0D6C2),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF332D24),
    onInverseSurface: Color(0xFFF5EFE3),
    inversePrimary: _gold,
  );

  static final ColorScheme _dark = const ColorScheme(
    brightness: Brightness.dark,
    primary: _gold,
    onPrimary: Color(0xFF3A2708),
    primaryContainer: Color(0xFF5A431F),
    onPrimaryContainer: Color(0xFFF3E2C4),
    secondary: Color(0xFFC9BCA1),
    onSecondary: Color(0xFF332D20),
    secondaryContainer: Color(0xFF433C2D),
    onSecondaryContainer: Color(0xFFE7DBC2),
    tertiary: Color(0xFF8CCBBF),
    onTertiary: Color(0xFF003730),
    tertiaryContainer: Color(0xFF1F4F47),
    onTertiaryContainer: Color(0xFFA8E7DB),
    error: Color(0xFFE79A8E),
    onError: Color(0xFF5C1408),
    errorContainer: Color(0xFF7A2618),
    onErrorContainer: Color(0xFFF9DAD3),
    surface: Color(0xFF15130E), // gece mürekkebi
    onSurface: Color(0xFFECE4D4), // krem
    onSurfaceVariant: Color(0xFFB6AB95),
    surfaceContainerLowest: Color(0xFF100E0A),
    surfaceContainerLow: Color(0xFF1B1813),
    surfaceContainer: Color(0xFF201D16),
    surfaceContainerHigh: Color(0xFF2A261D),
    surfaceContainerHighest: Color(0xFF353026),
    outline: Color(0xFF6E6451),
    outlineVariant: Color(0xFF3A3429),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFECE4D4),
    onInverseSurface: Color(0xFF2A261D),
    inversePrimary: _brass,
  );

  static ThemeData light() => _build(_light);

  static ThemeData dark() => _build(_dark);

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: kLatinFont,
      scaffoldBackgroundColor: scheme.surface,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: kSerifFont,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: scheme.onSurface,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: kLatinFont,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }

  // Başlık ailesinde serif (Lora), gövde/etikette Manrope.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle serif(TextStyle? s, {FontWeight weight = FontWeight.w600}) =>
        (s ?? const TextStyle()).copyWith(
          fontFamily: kSerifFont,
          fontWeight: weight,
          color: scheme.onSurface,
          height: 1.2,
        );
    return base.copyWith(
      displayLarge: serif(base.displayLarge, weight: FontWeight.w700),
      displayMedium: serif(base.displayMedium, weight: FontWeight.w700),
      displaySmall: serif(base.displaySmall, weight: FontWeight.w700),
      headlineLarge: serif(base.headlineLarge, weight: FontWeight.w700),
      headlineMedium: serif(base.headlineMedium, weight: FontWeight.w700),
      headlineSmall: serif(base.headlineSmall),
      titleLarge: serif(base.titleLarge),
      titleMedium: serif(base.titleMedium),
    );
  }

  /// Editöryel "kicker" etiket stili: küçük, harf aralıklı, büyük harf.
  static TextStyle kicker(BuildContext context, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: kLatinFont,
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color ?? scheme.onSurfaceVariant,
    );
  }

  /// Arapça metinler için Amiri tabanlı, satır aralığı geniş stil.
  static TextStyle arabic(BuildContext context, {double fontSize = 28}) {
    return TextStyle(
      fontFamily: kArabicFont,
      fontSize: fontSize,
      height: 1.95,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
