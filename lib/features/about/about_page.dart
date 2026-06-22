// about_page: uygulamanın amacı, kullanım rehberi, tarafsızlık ilkesi, kaynaklar
// ve yapay zeka uyarısı. Sınıf/eğitim ortamında güven ve şeffaflık için.

import 'package:flutter/material.dart';

import '../../widgets/reading_settings_sheet.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hakkında'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Okuma ayarları',
            onPressed: () => showReadingSettings(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Dört Kitap',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Tevrat, Zebur, İncil ve Kur’an’ın ortak konuları nasıl ele aldığını '
            'tarafsız ve karşılaştırmalı biçimde sunan bir okuma uygulaması.',
            style: theme.textTheme.bodyLarge
                ?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          const _Section(
            icon: Icons.menu_book_outlined,
            title: 'Nasıl kullanılır?',
            body: '• Akış: yukarı/aşağı kaydırarak konuları, sağa/sola kaydırarak '
                'aynı konunun her kitaptaki karşılığını görün. Üstte arama, '
                'tema dizini ve “günün konusu” düğmeleri vardır.\n'
                '• Tema dizini: tüm konuları kategorilere göre listeleyip arar, '
                'açarsınız.\n'
                '• Sunum modu: dizindeki bir kategoriyi (veya tümünü) tam ekran, '
                'büyük puntoyla sunar — sınıf/projeksiyon için.\n'
                '• Yan yana karşılaştır: bir konunun kapağındaki düğmeyle dört '
                'kitabı tek ekranda alt alta görün.\n'
                '• Sesli tilavet: Kur’an okuyucuda her ayetin yanındaki ▶ ile '
                'dinleyin (çevrimiçi gerekir).\n'
                '• Oku: Kur’an-ı Kerim (Arapça + Türkçe meal, ayet benzerlikleri) '
                've tüm Kitab-ı Mukaddes’i (Eski + Yeni Ahit) ayet ayet okuyun. '
                'Üstteki 🔍 ile tüm metinde arayın; kaldığınız yerden devam edin.\n'
                '• Kaydet, not & paylaş: bir ayetin yanındaki ⋮ menüsünden ayeti '
                'kaydedin, kişisel not ekleyin veya paylaşın; kayıtlar Favoriler › '
                'Ayetler’de toplanır.\n'
                '• Okuma ayarları: yazı boyutunu ve açık/koyu temayı değiştirin.',
          ),
          const _Section(
            icon: Icons.balance_outlined,
            title: 'Tarafsızlık ilkesi',
            body: 'Bu uygulama hiçbir geleneği yüceltmez ya da küçümsemez; '
                '“şu kitap şundan almış” türünden iddialarda bulunmaz. Yalnızca '
                '“benzer temayı şöyle ele alıyor” çerçevesini kullanır. Amaç '
                'karşılaştırmalı düşünmeyi ve okumayı kolaylaştırmaktır.',
          ),
          const _Section(
            icon: Icons.source_outlined,
            title: 'Kaynaklar',
            body: '• Kur’an: Arapça (Uthmânî hat) ve Türkçe meal (Elmalılı Hamdi '
                'Yazır) — kamu malı metinler.\n'
                '• Tevrat/Zebur/İncil: İngilizce World English Bible (kamu malı). '
                'Telifli Türkçe çeviriler gömülmez.\n'
                'Her ayetin kaynağı kart üzerindeki “Kaynak” bölümünden görülebilir.',
          ),
          const _Section(
            icon: Icons.smart_toy_outlined,
            title: 'Yapay zeka uyarısı',
            body: 'Bazı ayet benzerlikleri yapay zeka tarafından önerilmiştir ve '
                '“AI · doğrulanmamış” etiketiyle gösterilir. Bu öneriler akademik '
                'kullanımda mutlaka asıl kaynaklardan teyit edilmelidir. '
                '“Doğrulanmış” etiketli benzerlikler ise küratörlü referanslardır.',
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Eğitim ve karşılaştırmalı okuma amaçlıdır.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55)),
        ],
      ),
    );
  }
}
