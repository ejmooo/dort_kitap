// LegalPage testleri: feragatname sayfası açılabilmeli ve telif durumunu
// yanlış beyan etmemeli. Bu sayfanın içeriği hukuki sonuç doğurabilir; bir
// yeniden düzenlemede sessizce eksilmemesi için maddeler sabitlendi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dort_kitap/features/about/legal_page.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    // Sayfa bir ListView; varsayılan 800x600 görünümde ekran dışı maddeler hiç
    // inşa edilmez. Tamamını görebilmek için görünümü uzatıyoruz.
    tester.view.physicalSize = const Size(800, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: LegalPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('sekiz maddenin tamamını gösterir', (tester) async {
    await pump(tester);
    for (final title in [
      'Metinlerin kaynakları ve telif durumu',
      'Kutsal Kitap Yeni Çeviri hakkında bildirim',
      'Hak sahiplerine: kaldırma ve izin talepleri',
      'Dinî otorite beyanı',
      'Yapay zekâ ile üretilen içerik',
      'Kişisel veriler',
      'Sorumluluğun sınırlandırılması',
      'Uygulamanın kendi telifi',
    ]) {
      expect(find.text(title), findsOneWidget, reason: 'eksik madde: $title');
    }
  });

  testWidgets('Türkçe metnin telifli olduğunu açıkça söyler', (tester) async {
    await pump(tester);
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .join('\n');

    expect(texts.contains('telif hakkı saklıdır'), isTrue);
    expect(texts.contains('kamu malı değildir'), isTrue);
    // Eski, gerçek dışı beyanın geri sızmadığından emin ol.
    expect(texts.contains('Telifli Türkçe çeviriler gömülmez'), isFalse);
  });

  testWidgets('iletişim adresini gösterir', (tester) async {
    await pump(tester);
    expect(find.text(kLegalContactEmail), findsOneWidget);
  });
}
