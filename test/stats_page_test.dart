// StatsPage testleri: seri şeridinin gün etiketleri ve ilerleme sayıları.
// Şeridin bugünle bitmesi kolayca bir gün kayabilecek bir hesap — sabitlendi.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dort_kitap/features/stats/stats_page.dart';
import 'package:dort_kitap/models/bible_models.dart';
import 'package:dort_kitap/providers/bible_provider.dart';
import 'package:dort_kitap/providers/stats_provider.dart';

BibleBook _book(int nr, int chapters) => BibleBook(
      nr: nr,
      name: 'Kitap $nr',
      testament: 'eski',
      role: '',
      chapterCount: chapters,
      chapters: List.generate(
          chapters, (i) => BibleChapter(number: i + 1, verses: const [])),
    );

void main() {
  final today = DateTime.now();
  final base = DateTime(today.year, today.month, today.day);
  String k(int back) => dayKey(base.subtract(Duration(days: back)));

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        bibleProvider.overrideWith((ref) async => [_book(1, 50), _book(2, 40)]),
      ],
      child: const MaterialApp(home: StatsPage()),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'st_streak': 4,
      'st_best': 11,
      'st_days': 23,
      'st_last_day': k(0),
      'st_surahs': ['1', '2', '36', '112', '114'],
      'st_chapters': ['1:0', '19:22', '40:3'],
      'st_day_log': [k(0), k(1), k(2), k(3), k(5)],
      'favorite_theme_ids': ['a', 'b', 'c'],
      'saved_verses': jsonEncode([
        {'id': 'quran:2:255', 'scripture': 'quran', 'reference': 'Bakara 2:255',
         'preview': 'x', 'note': '', 'savedAt': 1},
      ]),
    });
  });

  testWidgets('seriyi ve en uzun seriyi gösterir', (tester) async {
    await pump(tester);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('günlük seri'), findsOneWidget);
    expect(find.text('Bugün okudun'), findsOneWidget);
    expect(find.text('En uzun serin: 11 gün'), findsOneWidget);
  });

  testWidgets('şerit bugünle biter — son etiket bugünün günü', (tester) async {
    await pump(tester);
    const labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];
    final expected = labels[DateTime.now().weekday - 1];

    // Yedi etiket, sonuncusu bugün olacak şekilde soldan sağa sıralı.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data)
        .where((t) => labels.contains(t))
        .toList();
    expect(texts.length, 7);
    expect(texts.last, expected);
  });

  testWidgets('ilerlemeyi veriden gelen bölüm toplamıyla gösterir',
      (tester) async {
    await pump(tester);
    expect(find.text('5 / 114  ·  %4'), findsOneWidget);
    // 50 + 40 = 90 bölüm; sabit bir sayı değil, override edilen veriden.
    expect(find.text('3 / 90  ·  %3'), findsOneWidget);
  });

  testWidgets('kayıtlı ayet ve favori sayaçlarını gösterir', (tester) async {
    await pump(tester);
    expect(find.text('kayıtlı ayet'), findsOneWidget);
    expect(find.text('favori konu'), findsOneWidget);
    expect(find.text('23'), findsOneWidget); // okuma günü
  });
}
