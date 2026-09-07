# Kutsal Kitap Yeni Çeviri — izin başvurusu

Bu dosya, uygulamadaki Türkçe Kitab-ı Mukaddes metni için hak sahibinden yazılı
izin istemek üzere hazırlanmış e-posta taslağını ve başvuru öncesi yapılması
gerekenleri içerir.

---

## Göndermeden önce

**Alıcıyı kendin doğrula.** Kitab-ı Mukaddes Şirketi'nin güncel iletişim
adresini `kitabimukaddes.com` üzerinden veya kuruma telefonla ulaşarak teyit et.
Bu taslakta bilerek bir e-posta adresi yazılmadı — yanlış adrese gönderilen bir
izin talebi cevapsız kalır ve sen izin aldığını sanırsın.

**Doğrulanması gereken ikinci nokta:** Yeni Çeviri'nin hakları Türkiye'de
Kitab-ı Mukaddes Şirketi'nde mi, yoksa Birleşik Kitab-ı Mukaddes Dernekleri
(United Bible Societies) gibi bir üst kuruluşta mı? İlk yazışmada bunu sormak,
yanlış muhataptan alınmış bir "olur"un işe yaramamasını önler.

**Aşağıdaki köşeli parantezleri doldur.** Özellikle indirme sayısı, mağaza
bağlantısı ve ticari model alanlarını boş bırakma — kurumlar bu üç şeye göre
karar veriyor.

---

## E-posta taslağı

**Konu:** Kutsal Kitap Yeni Çeviri metninin eğitim amaçlı bir mobil uygulamada kullanımı için izin talebi

---

Sayın Yetkili,

Adım [Ad Soyad]. "Dört Kitap" adlı, ücretsiz ve reklamsız bir mobil uygulamanın
geliştiricisiyim. Uygulama; Tevrat, Zebur, İncil ve Kur'an'ın ortak konuları
(adalet, merhamet, yaratılış, komşu sevgisi vb.) nasıl ele aldığını yan yana
gösteren, karşılaştırmalı okuma ve din eğitimi amaçlı bir çalışmadır.

Uygulamada Türkçe Tevrat, Zebur ve İncil metni olarak **Kutsal Kitap Yeni
Çeviri**'yi kullanmak istiyorum. Bu metnin telif hakkının kurumunuza ait
olduğunu biliyorum ve kullanımı izne bağlamak üzere size yazıyorum.

**Talebimin kapsamı**

- Kullanılacak metin: Kutsal Kitap Yeni Çeviri, Eski ve Yeni Ahit'in tamamı.
- Kullanım biçimi: Metin uygulamanın içine gömülü olarak, çevrimdışı okunabilecek
  şekilde yer alır. Kullanıcı ayet ayet okur, arama yapar ve tek tek ayetleri
  kopyalayabilir veya paylaşabilir.
- Değişiklik: Metinde hiçbir değişiklik, kısaltma, sadeleştirme veya yeniden
  yorumlama yapılmaz. Ayet ve bölüm numaralandırması korunur.
- Dağıtım: [Google Play / App Store / web] üzerinden, [ülke/bölge] kullanıcılarına.
- Ticari model: Uygulama tamamen ücretsizdir; reklam, uygulama içi satın alma,
  abonelik veya bağış toplama içermez. [Farklıysa burada açıkça belirt.]
- Öngörülen kullanıcı sayısı: [tahmini rakam veya "yeni yayınlanacak, mevcut
  kullanıcı yok"].

**Metnin kaynağı hakkında şeffaflık**

Metni hâlihazırda CrossWire Bible Society'nin dağıttığı bir sürümden aldım.
Ancak CrossWire'ın telif kaydında iznin "CrossWire'a verilmiş" olduğu
belirtiliyor; bu iznin benim uygulamamı kapsamadığını değerlendirdiğim için
doğrudan kurumunuza başvuruyorum. Uygulama bu yazışma sonuçlanana kadar
yayımlanmayacak / mevcut sürümde metin kullanılmayacaktır.
[Duruma göre bu cümlenin doğru olanını bırak, diğerini sil.]

**Taahhütlerim**

- Metnin her görüntülendiği ekranda ve uygulamanın "Telif Hakkı ve Feragatname"
  sayfasında, kurumunuzun belirleyeceği telif ibaresini eksiksiz gösteririm.
- Metni uygulama dışına toplu olarak aktarmayı (dışa aktarma, API, toplu kopyalama)
  engellerim; kullanıcı yalnızca tek tek ayet paylaşabilir.
- Kurumunuzun talebi hâlinde metni gecikmeksizin uygulamadan kaldırırım.
- İzin şartlarınıza uygun bir kullanım bedeli veya lisans ücreti söz konusuysa
  bunu görüşmeye açığım.

**Sorularım**

1. Bu kullanım için yazılı izin vermeniz mümkün müdür? Mümkünse izlenmesi gereken
   süreç ve varsa ücretlendirme nedir?
2. Kullanmamı istediğiniz telif ibaresinin tam metni nedir?
3. Ayet sayısı, bölüm sayısı veya kullanım biçimi konusunda uymam gereken bir
   sınır var mıdır?
4. Yeni Çeviri üzerindeki haklar kurumunuzda mı, yoksa başka bir kuruluşa mı
   başvurmam gerekir?

Uygulamayı incelemek isterseniz [demo bağlantısı / APK / ekran görüntüleri] ile
seve seve paylaşırım. Yanıtınız için şimdiden teşekkür eder, iyi çalışmalar
dilerim.

Saygılarımla,

[Ad Soyad]
[E-posta] · [Telefon]
[Varsa web sitesi / GitHub]

---

## Yanıt gelirse ne yapmalı

- **Olumlu ve yazılı:** İzin yazısını bu klasöre PDF olarak kaydet. Uygulamadaki
  `legal_page.dart` 2. maddesini "izin alınmıştır" olarak güncelle ve kurumun
  verdiği telif ibaresini birebir yerleştir.
- **Şartlı:** Şartları (ücret, ibare, sınır) yazılı olarak teyit ettir. Sözlü
  onaya güvenme.
- **Olumsuz veya yanıtsız (4–6 hafta):** `docs/telif-alternatifler.md` dosyasındaki
  açık lisanslı çevirilere geç. Yanıt gelmemesi izin anlamına gelmez.
