// Keşfet kartının ana düğmesi kısa ekranlarda görünür kalmalı.
//
// Kart içeriği bir iç kaydırmanın içinde; sığmadığında hata vermeden kayar ve
// "Oku" düğmesi hiçbir işaret olmadan kartın altında kalır. Orta segment
// telefonlarda (≈760 dp kullanılabilir yükseklik) tam olarak bu oluyordu.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dort_kitap/core/app_theme.dart';
import 'package:dort_kitap/features/shell/root_shell.dart';
import 'package:dort_kitap/models/theme_cluster.dart';
import 'package:dort_kitap/providers/themes_provider.dart';

// Gerçek verideki en uzun başlıklardan biri kadar uzun: üç satıra kırılır.
const _longTopic = ThemeCluster(
  id: 'uzun',
  title: 'Haksız Yere Cana Kıymanın Yasaklanması',
  category: 'Ahlak/Hukuk',
  similarity: 'near_identical',
  summary: 'Bir cana haksız yere kıymak dört gelenekte de ağır biçimde '
      'yasaklanır; can dokunulmazlığı ortak ilkedir.',
  entries: [],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'seen_intro': true}));

  // Gerçek kısıtı yakalamak için alt menüyü de içeren kabukla ölçülür;
  // yalnızca FeedPage ile ölçmek kartı olduğundan uzun gösterir.
  Future<void> pump(WidgetTester tester, Size size, {double scale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        themesProvider.overrideWith((ref) async => [_longTopic]),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const RootShell(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// "Oku" düğmesinin alt kenarı, onu kırpan kartın alt kenarının üstünde mi?
  void expectReadButtonVisible(WidgetTester tester) {
    final button = find.widgetWithText(FilledButton, 'Oku');
    expect(button, findsOneWidget);
    final card = find.ancestor(of: button, matching: find.byType(ClipRRect)).first;
    expect(
      tester.getRect(button).bottom,
      lessThanOrEqualTo(tester.getRect(card).bottom),
      reason: '"Oku" düğmesi kartın görünür alanının dışında kalıyor',
    );
  }

  for (final size in const [Size(392, 760), Size(360, 720)]) {
    testWidgets('${size.width.toInt()}×${size.height.toInt()} ekranda "Oku" '
        'düğmesi kartın içinde görünür', (tester) async {
      await pump(tester, size);
      expectReadButtonVisible(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('en büyük yazı boyutunda (%160) bile "Oku" görünür', (tester) async {
    // SettingsNotifier.maxScale — uygulamanın kendi ayarının üst sınırı.
    await pump(tester, const Size(392, 760), scale: 1.6);
    expectReadButtonVisible(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uzun ekranda tam tasarım korunur', (tester) async {
    await pump(tester, const Size(412, 915));
    expectReadButtonVisible(tester);
    // Dekoratif başlık yalnızca kompakt modda gizlenir.
    expect(find.text('DÖRT SES.\nORTAK BİR KEŞİF.'), findsOneWidget);
  });
}
