// Dört Kitap testleri: model fromJson davranışları, json_loader parse
// fonksiyonları ve temel widget'lar — ağ/asset gerektirmeyen hızlı testler.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dort_kitap/core/json_loader.dart';
import 'package:dort_kitap/models/parallel.dart';
import 'package:dort_kitap/models/theme_cluster.dart';
import 'package:dort_kitap/models/verse_entry.dart';
import 'package:dort_kitap/widgets/book_badge.dart';
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
}
