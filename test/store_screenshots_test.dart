// Mağaza ekran görüntüleri üreticisi. Normal test koşusunda hiçbir şey yapmaz;
// yalnızca açıkça istendiğinde çalışır:
//
//   flutter test test/store_screenshots_test.dart --dart-define=STORE_SHOTS=true
//
// Çıktı: docs/store/*.png — 1080 px genişliğinde, Play'in 2:1 en-boy sınırının
// içinde. Gerçek fontlar ve gerçek veri (themes.json, quran.json) kullanılır.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3'te Override tipi ana kütüphaneden değil misc'ten dışa açılıyor.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dort_kitap/core/app_theme.dart';
import 'package:dort_kitap/core/json_loader.dart';
import 'package:dort_kitap/features/feed/comparison_page.dart';
import 'package:dort_kitap/features/feed/theme_page.dart';
import 'package:dort_kitap/features/share/verse_image_sheet.dart';
import 'package:dort_kitap/features/shell/root_shell.dart';
import 'package:dort_kitap/features/stats/stats_page.dart';
import 'package:dort_kitap/models/bible_models.dart';
import 'package:dort_kitap/models/theme_cluster.dart';
import 'package:dort_kitap/providers/bible_provider.dart';
import 'package:dort_kitap/providers/stats_provider.dart';
import 'package:dort_kitap/providers/themes_provider.dart';

const bool _enabled = bool.fromEnvironment('STORE_SHOTS');

/// Mantıksal boyut. 1080 / 392 ≈ 2.755 piksel oranıyla 1080×2094 px çıkar;
/// en-boy oranı 1.94 — Play'in "uzun kenar kısa kenarın 2 katını geçemez"
/// sınırının içinde.
const Size _logical = Size(392, 760);
const double _pixelRatio = 1080 / 392;

void main() {
  late List<ThemeCluster> topics;

  setUpAll(() async {
    if (!_enabled) return;
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final (family, file) in [
      ('Manrope', 'assets/fonts/Manrope-Variable.ttf'),
      ('Lora', 'assets/fonts/Lora-Variable.ttf'),
      ('Amiri', 'assets/fonts/Amiri-Regular.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(file))).load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    topics = parseThemeClusters(
        await rootBundle.loadString('assets/data/themes.json'));
  });

  ThemeCluster topic(String id) => topics.firstWhere((t) => t.id == id);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget page, {
    List<Override> overrides = const [],
    Future<void> Function()? interact,
  }) async {
    tester.view.physicalSize = _logical;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        themesProvider.overrideWith((ref) async => topics),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: RepaintBoundary(key: key, child: page),
      ),
    ));
    await tester.pumpAndSettle();
    if (interact != null) {
      await interact();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull, reason: '$name çizilirken hata');

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: _pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('docs/store').create(recursive: true);
      await File('docs/store/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  setUp(() {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    String k(int back) => dayKey(base.subtract(Duration(days: back)));
    SharedPreferences.setMockInitialValues({
      // Karşılama penceresi ekran görüntülerinin önüne geçmesin.
      'seen_intro': true,
      // İstatistik ekranı boş görünmesin diye makul bir okuma geçmişi.
      'st_streak': 6,
      'st_best': 14,
      'st_days': 31,
      'st_last_day': k(0),
      'st_surahs': [for (var i = 1; i <= 23; i++) '$i'],
      'st_chapters': [for (var i = 0; i < 64; i++) '${1 + i ~/ 20}:${i % 20}'],
      'st_day_log': [k(0), k(1), k(2), k(3), k(4), k(5)],
      'favorite_theme_ids': ['tanri-merhameti', 'dua-yakaris', 'sukur'],
      'saved_verses': jsonEncode([
        for (final r in ['Bakara 2:255', 'Fâtiha 1:1', 'Mezmur 23:1', 'Matta 5:9'])
          {'id': r, 'scripture': 'quran', 'reference': r, 'preview': '',
           'note': '', 'savedAt': 1},
      ]),
    });
  });

  testWidgets('01 keşfet', (tester) async {
    if (!_enabled) return;
    await shoot(tester, '01-kesfet', const RootShell());
  });

  testWidgets('02 karşılaştırma', (tester) async {
    if (!_enabled) return;
    await shoot(
        tester, '02-karsilastirma', ComparisonPage(cluster: topic('tanri-merhameti')));
  });

  testWidgets('03 kur\'an sekmesi', (tester) async {
    if (!_enabled) return;
    await shoot(
      tester,
      '03-konu-kuran',
      Scaffold(body: ThemePage(cluster: topic('goklerin-yaratilisi'))),
      interact: () async {
        // Sekme etiketi BookPalette'ten gelir ("Kur’an"); sekme şeridi yatay
        // kaydığı için önce görünür alana getirilir. Bulunamazsa sessizce
        // atlamak yerine başarısız ol — yoksa işe yaramaz bir görüntü çıkar.
        final tab = find.textContaining('Kur');
        expect(tab, findsWidgets, reason: 'Kur’an sekmesi bulunamadı');
        await tester.ensureVisible(tab.last);
        await tester.pumpAndSettle();
        await tester.tap(tab.last);
      },
    );
  });

  testWidgets('04 görsel paylaşım', (tester) async {
    if (!_enabled) return;
    final quran = jsonDecode(await tester.runAsync(
        () => rootBundle.loadString('assets/data/quran.json')) as String);
    final surah = quran['surahs'][93]; // İnşirah
    final ayah = surah['ayahs'][4]; // 94:5 — kısa, kart taşmasın
    await shoot(
      tester,
      '04-gorsel-paylasim',
      VerseImagePage(
        text: ayah['tr'] as String,
        reference: '${surah['name']} 94:5',
        book: 'kuran',
        arabic: (ayah['ar'] as String).replaceAll('﻿', ''),
      ),
    );
  });

  testWidgets('05 istatistikler', (tester) async {
    if (!_enabled) return;
    BibleBook book(int nr, int n) => BibleBook(
          nr: nr,
          name: '',
          testament: 'eski',
          role: '',
          chapterCount: n,
          chapters: List.generate(
              n, (i) => BibleChapter(number: i + 1, verses: const [])),
        );
    await shoot(
      tester,
      '05-istatistikler',
      const StatsPage(),
      // Gerçek toplam: 1189 bölüm. bible.json'u (4.7 MB) yüklemek yerine aynı
      // toplamı veren hafif bir taklit.
      overrides: [
        bibleProvider.overrideWith((ref) async => [book(1, 929), book(40, 260)]),
      ],
    );
  });
}
