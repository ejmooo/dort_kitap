// Dört Kitap testleri: model fromJson davranışları, json_loader parse
// fonksiyonları ve temel widget'lar — ağ/asset gerektirmeyen hızlı testler.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dort_kitap/core/daily_topic.dart';
import 'package:dort_kitap/core/json_loader.dart';
import 'package:dort_kitap/models/parallel.dart';
import 'package:dort_kitap/models/theme_cluster.dart';
import 'package:dort_kitap/models/verse_entry.dart';
import 'package:dort_kitap/providers/stats_provider.dart';
import 'package:dort_kitap/widgets/book_badge.dart';
import 'package:dort_kitap/widgets/verse_image_card.dart';
import 'package:dort_kitap/widgets/similarity_chip.dart';

void main() {
  group('VerseEntry.fromJson', () {
    test('Kuran kaydını Arapça metinle ayrıştırır', () {
      final entry = VerseEntry.fromJson({
        'book': 'kuran',
        'reference': '17:33',
        'text': 'Türkçe meal',
        'text_ar': 'نص',
        'source': 'Diyanet',
      });

      expect(entry.book, 'kuran');
      expect(entry.hasTurkish, isTrue);
      expect(entry.hasArabic, isTrue);
      expect(entry.hasEnglish, isFalse);
    });

    test('Boş Türkçe metni eksik sayar, İngilizce yedeği korur', () {
      final entry = VerseEntry.fromJson({
        'book': 'tevrat',
        'reference': 'Çıkış 20:13',
        'text': '',
        'text_en': 'You shall not murder.',
        'source': 'WEB',
      });

      expect(entry.hasTurkish, isFalse);
      expect(entry.hasEnglish, isTrue);
    });
  });

  group('ThemeCluster.fromJson', () {
    test('Kümeyi ayrıştırır ve kitaba göre kayıt çözer', () {
      final cluster = ThemeCluster.fromJson({
        'id': 'x',
        'title': 'Başlık',
        'category': 'Kategori',
        'similarity': 'thematic',
        'summary': 'Özet',
        'entries': [
          {'book': 'kuran', 'reference': '1', 'text': 'a', 'source': 's'},
        ],
      });

      expect(cluster.id, 'x');
      expect(cluster.entries.length, 1);
      expect(cluster.entryFor('kuran'), isNotNull);
      expect(cluster.entryFor('zebur'), isNull);
    });
  });

  group('json_loader parse', () {
    test('parseQuran sûre ve ayetleri okur', () {
      const raw = '''
      {"surahs":[{"number":1,"name":"Fâtiha","ayahCount":2,
        "ayahs":[{"n":1,"g":1,"ar":"بِسْمِ","tr":"Rahman ve Rahim olan"},
                 {"n":2,"g":2,"ar":"ٱلْحَمْدُ","tr":"Hamd, âlemlerin Rabbine"}]}]}
      ''';
      final surahs = parseQuran(raw);
      expect(surahs, hasLength(1));
      expect(surahs.first.name, 'Fâtiha');
      expect(surahs.first.ayahs, hasLength(2));
      expect(surahs.first.ayahs.first.turkish, contains('Rahman'));
    });

    test('parseParallels ayet anahtarlarını ve origin bilgisini okur', () {
      const raw = '''
      {"2:153":[{"book":"zebur","reference":"Mezmur 37:7","note":"Sabır",
                 "origin":"curated","themeId":"sabir"}],
       "1:1":[{"book":"incil","reference":"Matta 6:9","note":"Dua","origin":"ai"}]}
      ''';
      final map = parseParallels(raw);
      expect(map, hasLength(2));
      expect(map['2:153']!.single.isAi, isFalse);
      expect(map['1:1']!.single.isAi, isTrue);
    });

    test('parseBible kitap > bölüm > ayet yapısını okur', () {
      const raw = '''
      {"books":[{"nr":19,"name":"Mezmurlar","testament":"eski","role":"zebur",
        "chapterCount":1,"chapters":[{"n":23,"verses":[{"n":1,"tr":"RAB çobanımdır."}]}]}]}
      ''';
      final books = parseBible(raw);
      expect(books.single.role, 'zebur');
      expect(books.single.chapters.single.verses.single.text,
          contains('çobanımdır'));
    });

    test('bozuk girdilerde boş sonuç döner, fırlatmaz', () {
      expect(parseQuran('{}'), isEmpty);
      expect(parseThemeClusters('{"beklenmedik":true}'), isEmpty);
      expect(parseParallels('[]'), isEmpty);
      expect(parseBible('{}'), isEmpty);
    });
  });

  group('modeller', () {
    test('Parallel.fromJson origin verilmezse "ai" varsayar', () {
      final p =
          Parallel.fromJson(const {'book': 'incil', 'reference': 'Matta 5:9'});
      expect(p.isAi, isTrue);
      expect(p.themeId, isNull);
    });
  });

  group('widgetlar', () {
    testWidgets('SimilarityChip üç düzeyi de metinle gösterir', (tester) async {
      for (final (similarity, expected) in [
        ('identical', 'BİREBİR ÖRTÜŞME'),
        ('near_identical', 'NEREDEYSE AYNI'),
        ('thematic', 'TEMATİK BENZERLİK'),
      ]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: SimilarityChip(similarity: similarity)),
        ));
        expect(find.text(expected), findsOneWidget);
      }
    });

    testWidgets('BookBadge kitap etiketini gösterir', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: BookBadge(book: 'zebur')),
      ));
      expect(find.text('Zebur'), findsOneWidget);
    });
  });

  group('okuma serisi', () {
    String key(DateTime d) => dayKey(d);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    test('dayKey ay ve günü iki haneye tamamlar', () {
      expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('bugün okunmuşsa seri canlıdır', () {
      final s = ReadingStats(currentStreak: 3, lastDay: key(today));
      expect(s.streakAlive, isTrue);
      expect(s.readToday, isTrue);
    });

    test('dün okunmuşsa seri hâlâ canlı ama bugün okunmamış sayılır', () {
      final s = ReadingStats(
          currentStreak: 3,
          lastDay: key(today.subtract(const Duration(days: 1))));
      expect(s.streakAlive, isTrue);
      expect(s.readToday, isFalse);
    });

    test('iki gün önceden beri okunmamışsa seri kopmuştur', () {
      final s = ReadingStats(
          currentStreak: 9,
          lastDay: key(today.subtract(const Duration(days: 2))));
      expect(s.streakAlive, isFalse);
    });

    test('hiç okunmamışsa seri canlı değildir', () {
      expect(const ReadingStats().streakAlive, isFalse);
      expect(const ReadingStats().isEmpty, isTrue);
    });

    test('recentDays son yedi günü bugün sonda olacak şekilde verir', () {
      final s = ReadingStats(days: {
        key(today),
        key(today.subtract(const Duration(days: 3))),
        key(today.subtract(const Duration(days: 9))), // pencere dışı
      });
      final week = s.recentDays(7);

      expect(week.length, 7);
      expect(week.last, isTrue); // bugün
      expect(week[3], isTrue); // 3 gün önce (6-3)
      expect(week[6 - 1], isFalse); // dün okunmamış
      expect(week.where((e) => e).length, 2); // 9 gün öncesi sayılmaz
    });
  });

  group('VerseImageCard', () {
    // Paylaşım kartı sabit genişliktedir; uzun ayetlerde taşmamalı.
    Future<void> pump(WidgetTester tester, String text, {String? arabic}) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VerseImageCard(
              text: text,
              reference: 'Bakara 2:255',
              book: 'kuran',
              arabic: arabic,
            ),
          ),
        ),
      ));
    }

    testWidgets('kısa ayeti taşmadan çizer', (tester) async {
      await pump(tester, 'De ki: O Allah birdir.');
      expect(tester.takeException(), isNull);
      expect(find.text('DÖRT KİTAP'), findsOneWidget);
      expect(find.text('Bakara 2:255'), findsOneWidget);
    });

    testWidgets('çok uzun ayeti taşmadan çizer', (tester) async {
      await pump(tester, 'Uzun bir meal cümlesi. ' * 40);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Arapça metin verilince onu da gösterir', (tester) async {
      await pump(tester, 'Meal metni', arabic: 'نص عربي');
      expect(tester.takeException(), isNull);
      expect(find.text('نص عربي'), findsOneWidget);
    });

    testWidgets('Arapça verilmezse yalnızca meali gösterir', (tester) async {
      await pump(tester, 'Meal metni');
      expect(find.text('نص عربي'), findsNothing);
    });
  });

  group('günün konusu', () {
    // Akış sayfası ve bildirim aynı formülü kullanır; kayarsa kullanıcı iki
    // farklı yerde iki farklı konu görür.
    test('aynı gün için hep aynı indeksi verir', () {
      final day = DateTime(2026, 5, 17);
      expect(dailyTopicIndex(day, 111), dailyTopicIndex(day, 111));
      expect(dailyTopicIndex(day, 111), dailyTopicIndex(DateTime(2026, 5, 17, 23, 59), 111));
    });

    test('ardışık günlerde bir ilerler', () {
      final a = dailyTopicIndex(DateTime(2026, 5, 17), 111);
      final b = dailyTopicIndex(DateTime(2026, 5, 18), 111);
      expect(b, (a + 1) % 111);
    });

    test('liste boyunca dolanır', () {
      final a = dailyTopicIndex(DateTime(2026, 5, 17), 10);
      final b = dailyTopicIndex(DateTime(2026, 5, 27), 10);
      expect(b, a);
    });

    test('tema yokken sıfır döner, patlamaz', () {
      expect(dailyTopicIndex(DateTime.now(), 0), 0);
    });

    test('sonuç her zaman geçerli bir indekstir', () {
      for (var i = 0; i < 400; i += 37) {
        final idx = dailyTopicIndex(kTopicEpoch.add(Duration(days: i)), 111);
        expect(idx, inInclusiveRange(0, 110));
      }
    });
  });
}
