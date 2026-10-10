# Google Play — mağaza girişi ve form cevapları

Play Console'a kopyalanacak metinler ve "Uygulama içeriği" bölümündeki formlar
için hazır cevaplar. Karakter sınırları kontrol edildi.

---

## Ana mağaza girişi

**Uygulama adı** (sınır 30): `Dört Kitap`

**Kısa açıklama** (sınır 80):

```
Tevrat, Zebur, İncil ve Kur'an'ın ortak konularını yan yana okuyun.
```

**Tam açıklama** (sınır 4000):

```
Dört Kitap; Tevrat, Zebur, İncil ve Kur'an'ın aynı konuları nasıl ele aldığını yan yana gösteren, eğitim amaçlı bir karşılaştırmalı okuma uygulamasıdır.

Adalet, merhamet, yaratılış, komşu sevgisi, can dokunulmazlığı… 111 ortak konuyu dört kitaptaki karşılıklarıyla birlikte keşfedin. Her konuyu tek tek okuyabilir ya da dört metni tek ekranda karşılaştırabilirsiniz.

KEŞFET
• 111 elle derlenmiş konu, kaynaklarıyla birlikte
• Konuları kategoriye göre süzün veya arayın
• Her gün yeni bir "günün konusu"
• Dört metni aynı ekranda karşılaştırın

OKU
• Kur'an-ı Kerim: 114 sûre, Arapça metin ve Türkçe meal
• Kitab-ı Mukaddes: Eski ve Yeni Ahit, 66 kitap, Türkçe
• Her ayetin altında diğer kitaplardaki benzer pasajlar
• Tüm metinde tam metin arama
• Kaldığınız yerden devam edin
• Kur'an için ayet ayet veya sûre boyunca sesli tilavet

KAYDET VE PAYLAŞ
• Konuları ve tek tek ayetleri favorilere ekleyin
• Ayetlere kişisel not yazın
• Ayetleri metin ya da şık bir görsel kart olarak paylaşın

SINIF VE SUNUM
• Sunum modu: bir kategoriyi tam ekran ve büyük puntoyla yansıtın
• Klavye ile ileri/geri gezinme

OKUMA ALIŞKANLIĞI
• Okuma istatistikleri ve günlük seri
• İsteğe bağlı günlük "günün konusu" hatırlatıcısı

TARAFSIZLIK İLKESİ
Dört Kitap hiçbir geleneği yüceltmez ya da küçümsemez ve "şu kitap şundan alınmıştır" türünden köken iddialarında bulunmaz. Yalnızca "benzer temayı şöyle ele alıyor" çerçevesini kullanır.

Bazı ayet benzerlikleri yapay zekâ tarafından önerilmiştir ve uygulamada açıkça "AI · doğrulanmamış" etiketiyle gösterilir. Elle derlenmiş eşleşmeler ise "Doğrulanmış" olarak işaretlenir.

GİZLİLİK
Hesap gerekmez. Hiçbir kişisel veri toplanmaz; favorileriniz, notlarınız ve istatistikleriniz yalnızca cihazınızda kalır. Reklam yoktur.

Metinler çevrimdışı çalışır; yalnızca sesli tilavet için internet gerekir.
```

**Kategori:** Kitaplar ve Referans *(alternatif: Eğitim)*

**Etiketler:** Din, Kitaplar, Eğitim, Okuma

---

## Uygulama içeriği formları

### Gizlilik politikası
`docs/gizlilik-politikasi.md` dosyasının yayımlanmış adresi. Play, herkese açık bir
URL ister — bkz. aşağıdaki "Gizlilik politikasını yayımlamak".

### Veri güvenliği (Data safety)

| Soru | Cevap |
|---|---|
| Uygulamanız gerekli kullanıcı verisi türlerinden herhangi birini topluyor veya paylaşıyor mu? | **Hayır** |
| Aktarılan tüm kullanıcı verileri şifreleniyor mu? | Kullanıcı verisi aktarılmıyor. Tilavet akışı HTTPS üzerinden. |
| Kullanıcılar verilerinin silinmesini isteyebilir mi? | Veri toplanmıyor; yerel veriler uygulama silinince silinir. |

*Neden "Hayır":* Koddaki tek ağ isteği everyayah.com'dan ses dosyası almak; bu
istek kullanıcıya ait bir veri taşımıyor. Analitik, reklam, çökme raporu yok.

### İçerik derecelendirmesi (IARC anketi)
- Kategori: **Referans, haber veya eğitim**
- Şiddet, cinsellik, küfür, kumar, kontrollü madde: **Hayır**
- Kullanıcılar arası etkileşim / içerik paylaşımı: **Hayır** *(paylaşım, sistemin kendi menüsüyle yapılıyor; uygulama içi sosyal özellik yok)*
- Konum paylaşımı: **Hayır**
- Dijital satın alma: **Hayır**

Not: Kutsal metinlerde savaş, ceza ve şiddet anlatıları bulunur. Anket bu
metinlerin varlığını sorarsa bunları "tarihî/dinî metin bağlamında anlatı"
olarak dürüstçe belirt.

### Hedef kitle
**18 yaş ve üzeri** seçilmesi önerilir. "13 yaş altı" seçilirse uygulama Aile
Politikası'na girer ve ek gereksinimler doğar; içerik bu yaş grubuna kapalı
değil ama özel olarak onlara tasarlanmadı.

### Reklamlar
**Hayır, uygulama reklam içermiyor.**

> ⚠️ Bunu değiştirmeden önce: Kur'an meali Tanzil'den **yalnızca ticari olmayan
> kullanım** şartıyla alındı. Reklam veya satın alma eklemek bu şartı bozar.

### Uygulama erişimi
**Tüm işlevler özel erişim gerektirmez** — giriş yok.

---

## Gerekli görseller

| Görsel | Boyut | Durum |
|---|---|---|
| Uygulama simgesi | 512×512 PNG | `assets/icon/icon.png` → 512'ye ölçekle |
| Öne çıkan görsel | 1024×500 PNG/JPG | `docs/store/feature-graphic.png` |
| Telefon ekran görüntüleri | en az 2, 16:9 veya 9:16 | `docs/store/` |

---

## Gizlilik politikasını yayımlamak

Depo GitHub'da olduğu için en kolay yol GitHub Pages:

1. GitHub'da depo → **Settings → Pages**
2. Source: **Deploy from a branch**, Branch: `main`, klasör: `/docs`
3. Birkaç dakika sonra politika şu adreste olur:
   `https://ejmooo.github.io/dort_kitap/gizlilik-politikasi`

Bu adres herkese açık olacağı için önce `docs/` klasöründeki her şeyin
yayımlanmaya uygun olduğundan emin ol — izin başvurusu taslağı ve telif
alternatifleri notları da aynı klasörde.
