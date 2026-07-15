# Dört Kitap

Dört kutsal kitabın — **Tevrat, Zebur, İncil ve Kur'an** — aynı/benzer konuları nasıl
ele aldığını, küratörlü tema kümeleri halinde ve Instagram-reels mantığıyla kaydırılan
bir akışta gösteren, çevrimdışı çalışan bir Flutter uygulaması.

> Amaç **karşılaştırmalı okuma ve eğitim**tir. Hiçbir gelenek yüceltilmez ya da
> küçümsenmez; "şu kitap şundan almış" türü iddialarda bulunulmaz — yalnızca
> "benzer temayı şöyle ele alıyor" çerçevesi kullanılır.

---

## Özellikler

- **Akış (reels):** yukarı/aşağı kaydır → konu değiştir, sağa/sola kaydır → kitap değiştir.
- **111 küratörlü tema**, dört kitaptaki karşılıklarıyla (kaynaklar her kartta erişilebilir).
- **Tema dizini:** tüm konuları kategorilere göre listeleyip arama.
- **Sunum modu:** bir kategoriyi (veya tümünü) tam ekran, büyük puntoyla sunma — sınıf/projeksiyon için.
- **Yan yana karşılaştırma:** bir konunun dört kitaptaki metnini tek ekranda.
- **Kur'an okuyucu:** 114 sûre / 6236 ayet, Arapça (Uthmânî) + Türkçe meal; her ayetin altında diğer kitaplardaki **benzer pasajlar**.
- **Sesli tilavet:** ayet ayet dinleme (çevrimiçi gerekir).
- **Kitab-ı Mukaddes okuyucu:** Eski + Yeni Ahit, 66 kitap, Türkçe.
- **Favoriler & notlar:** konuları ve tek tek ayetleri kaydetme, üzerlerine kişisel not.
- **Tam metin arama**, **kaldığın yere devam**, **paylaşım**.
- **Okuma ayarları:** yazı boyutu + açık/koyu/sistem teması (kalıcı).
- **Çevrimdışı öncelikli:** tüm metinler uygulama içinde gömülü; fontlar dahil internet gerektirmez (tilavet hariç).

### Benzerlik etiketleri
- 🟢 **Doğrulanmış** — küratörlü, kaynaklı eşleşmeler.
- 🟠 **AI · doğrulanmamış** — yapay zeka önerisi; akademik kullanımda kaynaktan teyit gerekir.

---

## Teknoloji

- **Flutter + Dart** (null-safety), platformlar: **Android + Web**
- **Riverpod** (klasik `Notifier`/`NotifierProvider`, kod üretimi yok)
- `shared_preferences` (favoriler, notlar, ayarlar, ilerleme), `share_plus`, `audioplayers`
- Çevrimdışı fontlar: **Manrope** (Latin) + **Amiri** (Arapça)
- Backend yok — veri `assets/data/*.json`'dan okunur

---

## Kurulum

```bash
flutter pub get
flutter run -d chrome      # veya: flutter run -d <android-cihaz>
```

Gereksinim: Flutter 3.44+ / Dart 3.12+.

---

## Proje yapısı

```
lib/
  core/          app_theme.dart, json_loader.dart
  models/        theme_cluster, verse_entry, quran_models, bible_models, parallel, saved_verse
  providers/     themes, filter, favorites, settings, quran, bible,
                 verse_bookmarks, reading_progress, audio
  features/
    shell/         root_shell (alt menü)
    feed/          feed_page, theme_page, verse_card, comparison_page
    index/         theme_index_page
    presentation/  presentation_page
    library/       library_page (Oku sekmesi)
    quran/         quran_page, surah_page
    bible/         bible_page, bible_book_page, bible_chapter_page
    search/        scripture_search_page
    favorites/     favorites_page
    detail/        source_sheet
    about/         about_page
  widgets/       book_badge, similarity_chip, page_dots, parallel_list,
                 reading_settings_sheet, verse_menu, share_helper

assets/data/     themes.json, quran.json, bible.json, parallels.json
tools/           veri üretim script'leri (Python)
```

---

## Veri üretimi (`tools/`)

Tüm veri açık kaynaklardan Python script'leriyle üretilir; backend yoktur.

```bash
python3 tools/build_themes.py      # tema kümeleri        -> assets/data/themes.json
python3 tools/build_quran.py       # tüm Kur'an           -> assets/data/quran.json
python3 tools/build_bible.py       # tüm Kitab-ı Mukaddes -> assets/data/bible.json
python3 tools/build_parallels.py   # ayet düzeyi benzerlik -> assets/data/parallels.json
```

- **`tools/seed.json`** temaların referans listesidir; metinler script'lerce doldurulur.
- **`build_parallels.py`** küratörlü referansları (`seed.json`) ayet düzeyine bağlar.

### Tüm Kur'an için AI paralelleri (opsiyonel, ücretli)

Şu an ~165 ayette benzerlik var (küratörlü + örnek). Tüm 6236 ayeti yapay zeka ile
doldurmak için Anthropic API anahtarı gerekir:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
python3 tools/generate_parallels.py 112 114   # önce küçük bir dilimle test et
python3 tools/generate_parallels.py           # tümü (kaldığı yerden devam eder)
python3 tools/build_parallels.py              # küratörlü + AI birleştir
```

Maliyet token başınadır (varsayılan model `claude-sonnet-4-6`); küçük bir dilimle
deneyip Console > Usage'dan ölçmek önerilir. Üretilen tüm paraleller arayüzde
**"AI · doğrulanmamış"** olarak etiketlenir.

---

## Veri kaynakları ve telif

| Metin | Kaynak | Durum |
|---|---|---|
| Kur'an — Arapça (Uthmânî) | alquran.cloud | Kamu malı |
| Kur'an — Türkçe meal | Elmalılı Hamdi Yazır (alquran.cloud) | Kamu malı |
| Kur'an — İngilizce | M. Pickthall (alquran.cloud) | Kamu malı |
| Tevrat/Zebur/İncil — İngilizce | World English Bible (bible-api.com) | Kamu malı |
| Tevrat/Zebur/İncil — Türkçe | Kutsal Kitap, Yeni Çeviri (getbible.net / CrossWire) | **Telifli, dağıtım izinli** |
| Tilavet sesi | Mishary Alafasy (cdn.islamic.network) | Çevrimiçi yayınlanır |

> ⚠️ **Türkçe Kitab-ı Mukaddes metni telif altındadır** (CrossWire üzerinden dağıtım izinli).
> Bu depoyu yayınlamadan/dağıtmadan önce ilgili lisansları teyit etmeniz önerilir.
> İngilizce (kamu malı) metinler veride yedek olarak saklanır.

---

## Sorumluluk / tarafsızlık

Bu uygulama akademik ve karşılaştırmalı okuma amaçlıdır, dinî bir otorite değildir.
Yapay zeka tarafından önerilen benzerlikler doğrulanmamıştır ve mutlaka asıl
kaynaklardan teyit edilmelidir.

---



---

## Lisans

Uygulama **kodu** için bir açık kaynak lisansı (ör. MIT) önerilir — tercihinize göre
bir `LICENSE` dosyası ekleyin. **Gömülü kutsal metinler** kendi kaynak lisanslarına
tabidir (yukarıdaki tabloya bakın) ve kod lisansı kapsamında değildir.
