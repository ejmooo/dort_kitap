import 'dart:io';
import 'dart:ui' as ui;

import 'package:dort_kitap/core/app_theme.dart';
import 'package:dort_kitap/features/shell/root_shell.dart';
import 'package:dort_kitap/core/json_loader.dart';
import 'package:dort_kitap/features/feed/feed_page.dart';
import 'package:dort_kitap/features/feed/theme_page.dart';
import 'package:dort_kitap/features/library/library_page.dart';
import 'package:dort_kitap/models/theme_cluster.dart';
import 'package:dort_kitap/models/verse_entry.dart';
import 'package:dort_kitap/providers/themes_provider.dart';
import 'package:dort_kitap/widgets/reading_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _topic = ThemeCluster(
  id: 'merhamet',
  title: 'Merhamet ve şefkat',
  category: 'Erdemler',
  similarity: 'thematic',
  summary:
      'Merhamet, dört gelenekte de insanı insana yaklaştıran ortak bir çağrı. Metinlerin arasında kendi keşif yolculuğuna çık.',
  entries: [
    VerseEntry(
      book: 'tevrat',
      reference: 'Örnek kaynak',
      text: 'Örnek okuma metni.',
      source: 'Test',
    ),
  ],
);
const _second = ThemeCluster(
  id: 'adalet',
  title: 'Adalet',
  category: 'Toplum',
  similarity: 'thematic',
  summary: 'Adalet üzerine.',
  entries: [],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'seen_intro': true}));

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(390, 844),
    double scale = 1,
    bool dark = false,
    GlobalKey? captureKey,
    List<ThemeCluster>? topics,
    bool reduceMotion = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themesProvider.overrideWith(
            (ref) async => topics ?? [_topic, _second],
          ),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduceMotion,
            ),
            child: child!,
          ),
          home: RepaintBoundary(key: captureKey, child: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('topic tabs navigate to text and preserve bookmark action', (
    tester,
  ) async {
    await pump(tester, const Scaffold(body: ThemePage(cluster: _topic)));
    await tester.tap(find.byTooltip('Favorilere ekle'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Favorilerden çıkar'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tevrat'));
    await tester.pumpAndSettle();
    expect(find.text('Örnek okuma metni.'), findsOneWidget);
    await tester.tap(find.text('Genel bakış'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Favorilerden çıkar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search empty state resets and category sheet filters', (
    tester,
  ) async {
    await pump(tester, const FeedPage());
    await tester.tap(find.byTooltip('Konu ara'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bulunamayacak');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tüm konulara dön'));
    await tester.pumpAndSettle();
    expect(find.text(_topic.title), findsOneWidget);
    await tester.tap(find.text('Tüm konular'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toplum'));
    await tester.pumpAndSettle();
    expect(find.text('Adalet'), findsOneWidget);
    expect(find.text(_topic.title), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('small screen and large text remain scrollable ($dark)', (
      tester,
    ) async {
      await pump(
        tester,
        const FeedPage(),
        size: const Size(320, 568),
        scale: 1.8,
        dark: dark,
      );
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byKey(const ValueKey('book-tabs')),
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tevrat'));
      await tester.tap(find.text('Tevrat'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Okuma ayarları'));
      await tester.pumpAndSettle();
      expect(find.text('Okuma ayarları'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('library supports enlarged text', (tester) async {
    await pump(
      tester,
      const LibraryPage(),
      size: const Size(320, 568),
      scale: 1.8,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings can change appearance with enlarged text', (
    tester,
  ) async {
    await pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showReadingSettings(context),
            child: const Text('Ayarlar'),
          ),
        ),
      ),
      scale: 1.8,
    );
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Koyu'));
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final reduceMotion in [true, false]) {
    testWidgets(
      'navigation preserves topic position (reduce motion: $reduceMotion)',
      (tester) async {
        await pump(tester, const RootShell(), reduceMotion: reduceMotion);
        await tester.tap(find.byTooltip('Sonraki konu'));
        await tester.pumpAndSettle();
        expect(find.text('Adalet'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Oku'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Kütüphane'), findsOneWidget);
        await tester.tap(find.text('Keşfet'));
        await tester.pumpAndSettle();
        expect(find.text('Adalet'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('render atlas preview', (tester) async {
    if (!const bool.fromEnvironment('UI_PREVIEW')) return;
    await tester.runAsync(() async {
      for (final family in ['Manrope', 'Lora']) {
        final loader = FontLoader(family)
          ..addFont(rootBundle.load('assets/fonts/$family-Variable.ttf'));
        await loader.load();
      }
    });
    await tester.runAsync(() async {
      final loader = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await loader.load();
    });
    final topics = parseThemeClusters(
      await tester.runAsync(
            () => rootBundle.loadString('assets/data/themes.json'),
          ) ??
          '[]',
    );
    final key = GlobalKey();
    await pump(tester, const RootShell(), captureKey: key, topics: topics);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/ui-preview').create(recursive: true);
      await File(
        'build/ui-preview/atlas.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
