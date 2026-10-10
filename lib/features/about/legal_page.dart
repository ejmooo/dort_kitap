// legal_page: Telif Hakkı ve Feragatname. Mağaza sürümünde erişilebilir olması
// ve uygulamanın hangi metni hangi statüde kullandığını açıkça beyan etmesi
// gerekir. Hakkında sayfasından açılır.
//
// UYARI: Bu metin hukuki danışmanlık değildir; yayına çıkmadan önce bir avukata
// (özellikle FSEK ve mağaza politikaları açısından) okutulmalıdır.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';

/// Kaldırma/izin taleplerinin gönderileceği adres.
///
/// TODO(ejmo): yayına çıkmadan önce gerçek adresle değiştir. Kişisel e-posta
/// yerine bu iş için ayrılmış bir adres kullanmak daha iyidir.
const String kLegalContactEmail = 'iletisim@example.com';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Telif Hakkı ve Feragatname')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Text('SON GÜNCELLEME · EYLÜL 2026', style: AppTheme.kicker(context)),
          const SizedBox(height: 14),
          Text(
            'Dört Kitap; Tevrat, Zebur, İncil ve Kur’an’ın ortak konuları nasıl '
            'ele aldığını karşılaştırmalı olarak sunan, eğitim amaçlı bir okuma '
            'uygulamasıdır. Aşağıda uygulamada yer alan metinlerin kaynakları, '
            'telif durumları ve uygulamanın sorumluluk sınırları açıklanmıştır.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 26),

          const _Article(
            number: '1',
            title: 'Metinlerin kaynakları ve telif durumu',
            body:
                'Uygulamada yer alan kutsal metinler uygulamanın geliştiricisine '
                'ait değildir. Her metin, aşağıda belirtilen kaynaktan alınmıştır '
                've telif hakkı ilgili hak sahiplerine aittir:\n\n'
                '• Kur’an-ı Kerim — Arapça (Uthmânî hat): kamu malı.\n'
                '• Kur’an-ı Kerim — Türkçe meal: Elmalılı Hamdi Yazır mealinin '
                'sadeleştirilmiş metni; Tanzil Projesi aracılığıyla, ticari olmayan '
                'kullanım koşuluyla alınmıştır. Elmalılı’nın özgün meali kamu '
                'malıdır; sadeleştirilmiş metnin hakları sadeleştirene aittir.\n'
                '• Kur’an-ı Kerim — İngilizce meal: M. Pickthall; kamu malı.\n'
                '• Tevrat / Zebur / İncil — İngilizce: World English Bible; kamu malı.\n'
                '• Tevrat / Zebur / İncil — Türkçe: Kutsal Kitap Yeni Çeviri. '
                'Bu metnin telif hakkı Kitab-ı Mukaddes Şirketi ve ilgili hak '
                'sahiplerine aittir (aşağıdaki 2. maddeye bakınız).\n'
                '• Kur’an tilaveti: Mishary Alafasy kaydı; uygulama içinde '
                'saklanmaz, üçüncü taraf sunucudan çevrimiçi olarak akıtılır ve '
                'telif hakkı kayıt sahibine aittir.',
          ),

          const _Article(
            number: '2',
            title: 'Kutsal Kitap Yeni Çeviri hakkında bildirim',
            body:
                'Uygulamadaki Türkçe Tevrat, Zebur ve İncil metni “Kutsal Kitap '
                'Yeni Çeviri”ye dayanmaktadır. Bu metin kamu malı değildir; '
                'telif hakkı saklıdır.\n\n'
                'Metin, CrossWire Bible Society aracılığıyla dağıtılan bir '
                'sürümden alınmıştır. Söz konusu dağıtım izninin uygulamamızı da '
                'kapsayıp kapsamadığı hak sahibiyle netleştirilmektedir. '
                'Geliştirici, hak sahibinden yazılı izin almak üzere başvuruda '
                'bulunmuştur.\n\n'
                'Hak sahibinin talebi hâlinde bu metin uygulamadan gecikmeksizin '
                'kaldırılacak ve yerine kamu malı ya da açık lisanslı bir Türkçe '
                'çeviri konulacaktır. Metin hiçbir şekilde değiştirilmemiş, '
                'kısaltılmamış veya yeniden yorumlanmamıştır; yalnızca okuma ve '
                'karşılaştırma amacıyla görüntülenmektedir.',
          ),

          const _Article(
            number: '3',
            title: 'Hak sahiplerine: kaldırma ve izin talepleri',
            body:
                'Uygulamada hak sahibi olduğunuz bir metnin izinsiz kullanıldığını '
                'düşünüyorsanız lütfen bizimle iletişime geçin. Talebiniz '
                'incelenecek ve haklı bulunması hâlinde ilgili içerik makul süre '
                'içinde uygulamadan kaldırılacaktır. Talebinizde hangi metne, '
                'hangi sıfatla ve hangi gerekçeyle itiraz ettiğinizi belirtmeniz '
                'işlemi hızlandırır.',
          ),

          _ContactRow(email: kLegalContactEmail),
          const SizedBox(height: 22),

          const _Article(
            number: '4',
            title: 'Dinî otorite beyanı',
            body:
                'Bu uygulama dinî bir otorite, mezhep, cemaat veya kurum '
                'değildir; hiçbiriyle bağlantılı ya da bunlar tarafından '
                'onaylanmış değildir. Hiçbir geleneği yüceltmez veya '
                'küçümsemez ve “şu kitap şundan alınmıştır” türünden köken '
                'iddialarında bulunmaz. Yalnızca “benzer temayı şöyle ele '
                'alıyor” çerçevesini kullanır.\n\n'
                'İçerik, dinî hüküm veya fetva niteliği taşımaz. Dinî konularda '
                'bağlayıcı bilgi için ilgili geleneğin yetkili mercilerine ve '
                'asıl kaynaklara başvurulmalıdır.',
          ),

          const _Article(
            number: '5',
            title: 'Yapay zekâ ile üretilen içerik',
            body:
                'Ayetler arasındaki benzerliklerin bir bölümü yapay zekâ '
                'tarafından önerilmiştir ve uygulamada “AI · doğrulanmamış” '
                'etiketiyle açıkça işaretlenir. Bu öneriler insan denetiminden '
                'geçmemiş olabilir; hata, eksik veya yanıltıcı eşleştirme '
                'içerebilir. Akademik ya da eğitsel kullanımda mutlaka asıl '
                'kaynaklardan teyit edilmelidir.\n\n'
                '“Doğrulanmış” etiketli benzerlikler ise elle derlenmiş, '
                'kaynaklı eşleştirmelerdir.',
          ),

          const _Article(
            number: '6',
            title: 'Kişisel veriler',
            body:
                'Uygulama hesap açmayı gerektirmez ve kişisel veri toplamaz. '
                'Favoriler, kaydedilen ayetler, notlar, okuma ilerlemesi ve '
                'istatistikler yalnızca cihazınızda saklanır; hiçbir sunucuya '
                'gönderilmez. Uygulamayı silmeniz hâlinde bu veriler de silinir.\n\n'
                'Tek istisna, isteğe bağlı Kur’an tilaveti özelliğidir: sesi '
                'çaldığınızda cihazınız üçüncü taraf bir sunucuya bağlanır ve bu '
                'bağlantı ilgili sunucunun kendi kayıtlarına tabidir.',
          ),

          const _Article(
            number: '7',
            title: 'Sorumluluğun sınırlandırılması',
            body:
                'Uygulama “olduğu gibi” sunulmaktadır. Metinlerin ve '
                'benzerliklerin doğruluğu, eksiksizliği veya belirli bir amaca '
                'uygunluğu konusunda açık ya da örtülü bir garanti verilmez. '
                'Uygulamadaki bilgilere dayanılarak alınan kararlardan '
                'geliştirici sorumlu tutulamaz.',
          ),

          const _Article(
            number: '8',
            title: 'Uygulamanın kendi telifi',
            body:
                'Uygulamanın arayüzü, tasarımı, kaynak kodu ve elle derlenmiş '
                'tema/benzerlik verisi © 2026 ejmo. Kutsal metinlerin telifi bu '
                'kapsamda değildir ve 1. maddede belirtilen hak sahiplerine '
                'aittir.',
          ),

          const SizedBox(height: 10),
          Text(
            'Bu sayfa bilgilendirme amaçlıdır ve hukuki görüş niteliği taşımaz.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Article extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _Article({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(number,
                  style: TextStyle(
                    fontFamily: kSerifFont,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  )),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(height: 1.6, color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}

/// İletişim adresi satırı — dokununca panoya kopyalar (uygulama içinde
/// e-posta istemcisi açmak için ek bağımlılık gerekmesin diye).
class _ContactRow extends StatelessWidget {
  final String email;

  const _ContactRow({required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: email));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adres panoya kopyalandı')),
          );
        }
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.mail_outline, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(email,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.copy_outlined,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
