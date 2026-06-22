// Model katmanı için temel birim testleri: JSON ayrıştırma ve metin
// durumlarının (Türkçe/Arapça/İngilizce yedek) doğru çözümlenmesi.

import 'package:flutter_test/flutter_test.dart';

import 'package:dort_kitap/models/theme_cluster.dart';
import 'package:dort_kitap/models/verse_entry.dart';

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
}
