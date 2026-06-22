#!/usr/bin/env python3
# build_themes.py: tools/seed.json'daki tema + referans listesini açık kaynaklardan
# gerçek metinle doldurup assets/data/themes.json'u (UI şemasıyla) yeniden üretir.
#
# Kaynaklar:
#   - Kuran Arapça (Uthmânî) + Türkçe meal (Elmalılı) + İngilizce Pickthall -> api.alquran.cloud
#   - Tevrat/Zebur/İncil Türkçe (Kutsal Kitap) -> getbible.net (CrossWire dağıtım izni)
#   - Tevrat/Zebur/İncil İngilizce (World English Bible, kamu malı) -> bible-api.com

import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED_PATH = os.path.join(ROOT, "tools", "seed.json")
OUT_PATH = os.path.join(ROOT, "assets", "data", "themes.json")
# Başarılı yanıtlar diske önbelleklenir: tekrar çalıştırmada ağ/limit derdi olmaz.
CACHE_PATH = os.path.join(ROOT, "tools", ".fetch_cache.json")

QURAN_EDITIONS = "quran-uthmani,tr.yazir,en.pickthall"
QURAN_SOURCE = ("Arapça: Kur'an-ı Kerim (Uthmânî hat) · Türkçe meal: Elmalılı "
                "Hamdi Yazır · İngilizce: M. Pickthall — kaynak: alquran.cloud "
                "(kamu malı metinler)")
BIBLE_SOURCE = ("Türkçe: Kutsal Kitap (Yeni Çeviri) — CrossWire/getbible.net · "
                "İngilizce: World English Bible (kamu malı) — bible-api.com")

# İncil/Tevrat/Zebur kitap adlarının getbible.net kitap numaraları.
GETBIBLE_BOOK = {
    "Genesis": 1, "Exodus": 2, "Leviticus": 3, "Numbers": 4, "Deuteronomy": 5,
    "Psalms": 19, "Matthew": 40, "Mark": 41, "Luke": 42, "John": 43,
}

# alquran.cloud, Fâtiha dışındaki surelerin ilk ayetine Besmele'yi ekler; kartlar
# arasında tutarlılık için bu önek (harekeden bağımsız) temizlenir.
BASMALA_SKELETON = ["بسم", "الله",
                    "الرحمن",
                    "الرحيم"]
_HARAKAT = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭـ]")

# İncil kitap adları (İngilizce -> Türkçe) referansları yerelleştirmek için.
TR_BOOK = {
    "Genesis": "Yaratılış",
    "Exodus": "Çıkış",
    "Leviticus": "Levililer",
    "Numbers": "Çölde Sayım",
    "Deuteronomy": "Yasa'nın Tekrarı",
    "Psalms": "Mezmur",
    "Matthew": "Matta",
    "Mark": "Markos",
    "Luke": "Luka",
    "John": "Yuhanna",
}

BIBLE_BOOKS = ("tevrat", "zebur", "incil")


def _skeleton(word):
    # Hareke/şedde/uzatma işaretlerini ve wasla elifini (ٱ) kaldırır.
    return _HARAKAT.sub("", word).replace("ٱ", "ا")


def strip_basmala(text):
    words = text.split()
    if len(words) >= 4 and [_skeleton(w) for w in words[:4]] == BASMALA_SKELETON:
        return " ".join(words[4:])
    return text


_cache = {}


def load_cache():
    global _cache
    if os.path.exists(CACHE_PATH):
        try:
            with open(CACHE_PATH, encoding="utf-8") as fh:
                _cache = json.load(fh)
        except Exception:
            _cache = {}


def save_cache():
    with open(CACHE_PATH, "w", encoding="utf-8") as fh:
        json.dump(_cache, fh, ensure_ascii=False)


def http_get_json(url, retries=6):
    if url in _cache:
        return _cache[url]
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "dort-kitap/1.0"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            _cache[url] = data
            save_cache()  # kısmi ilerlemeyi koru
            time.sleep(1.1)  # nazik throttle (bible-api limiti için)
            return data
        except urllib.error.HTTPError as exc:
            last = exc
            time.sleep(15 if exc.code == 429 else 2 * (attempt + 1))
        except Exception as exc:  # ağ hatasında bekleyip tekrar dene
            last = exc
            time.sleep(2 * (attempt + 1))
    raise last


def normalize(text):
    return re.sub(r"\s+", " ", (text or "").replace("\n", " ")).strip()


def fetch_quran(ref):
    """ref: '2:153' veya '103:1-3' -> (arapca, turkce, ingilizce)."""
    surah, ayahs = ref.split(":")
    if "-" in ayahs:
        start, end = ayahs.split("-")
        numbers = range(int(start), int(end) + 1)
    else:
        numbers = [int(ayahs)]
    arabic, turkish, english = [], [], []
    for ayah in numbers:
        url = ("https://api.alquran.cloud/v1/ayah/"
               f"{surah}:{ayah}/editions/{QURAN_EDITIONS}")
        data = http_get_json(url)["data"]
        for edition in data:
            ident = edition["edition"]["identifier"]
            if ident == "quran-uthmani":
                text = normalize(edition["text"])
                # Fâtiha (1) hariç ilk ayetteki Besmele önekini at.
                if ayah == 1 and surah != "1":
                    text = strip_basmala(text)
                arabic.append(text)
            elif ident.startswith("tr."):
                turkish.append(normalize(edition["text"]))
            else:
                english.append(normalize(edition["text"]))
    return " ".join(arabic), " ".join(turkish), " ".join(english)


def fetch_bible(ref):
    """ref: 'Exodus 20:13' veya 'Psalms 37:7-9' -> ingilizce metin (WEB)."""
    url = "https://bible-api.com/" + urllib.parse.quote(ref) + "?translation=web"
    data = http_get_json(url)
    return normalize(data.get("text", ""))


def _verse_range(chap_verse):
    chap, verses = chap_verse.split(":")
    if "-" in verses:
        start, end = verses.split("-")
        return int(chap), range(int(start), int(end) + 1)
    return int(chap), [int(verses)]


def fetch_bible_turkish(ref):
    """ref: 'Exodus 20:13' -> Türkçe metin (Kutsal Kitap, getbible.net)."""
    book, chap_verse = ref.rsplit(" ", 1)
    bnum = GETBIBLE_BOOK.get(book)
    if bnum is None:
        return ""
    chapter, wanted = _verse_range(chap_verse)
    url = f"https://api.getbible.net/v2/turkish/{bnum}/{chapter}.json"
    try:
        data = http_get_json(url)
    except Exception:
        return ""
    wanted = set(wanted)
    parts = [normalize(v.get("text", ""))
             for v in data.get("verses", []) if v.get("verse") in wanted]
    return " ".join(p for p in parts if p)


def tr_reference(ref):
    book, chap_verse = ref.rsplit(" ", 1)
    return f"{TR_BOOK.get(book, book)} {chap_verse}"


def build():
    load_cache()
    with open(SEED_PATH, encoding="utf-8") as fh:
        seed = json.load(fh)

    clusters = []
    warnings = []
    for theme in seed:
        refs = theme["refs"]
        entries = []

        # Kanonik kart sırası: tevrat, zebur, incil, kuran.
        for book in BIBLE_BOOKS:
            if book not in refs:
                continue
            english = fetch_bible(refs[book])
            turkish_bible = fetch_bible_turkish(refs[book])
            if not turkish_bible:
                warnings.append(f"{theme['id']} · {book} · {refs[book]} -> TR boş")
            entries.append({
                "book": book,
                "reference": tr_reference(refs[book]),
                "text": turkish_bible,
                "text_en": english,
                "source": BIBLE_SOURCE,
            })

        if "kuran" in refs:
            arabic, turkish, english = fetch_quran(refs["kuran"])
            if not arabic:
                warnings.append(f"{theme['id']} · kuran · {refs['kuran']} -> boş")
            entries.append({
                "book": "kuran",
                "reference": refs["kuran"],
                "text": turkish,
                "text_ar": arabic,
                "text_en": english,
                "source": QURAN_SOURCE,
            })

        clusters.append({
            "id": theme["id"],
            "title": theme["title"],
            "category": theme["category"],
            "similarity": theme["similarity"],
            "summary": theme["summary"],
            "entries": entries,
        })
        print(f"✓ {theme['id']} ({len(entries)} kayıt)")

    with open(OUT_PATH, "w", encoding="utf-8") as fh:
        json.dump(clusters, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    print(f"\nYazıldı: {OUT_PATH}  —  {len(clusters)} tema")
    if warnings:
        print(f"\nUYARILAR ({len(warnings)} boş metin):")
        for line in warnings:
            print("  ! " + line)


if __name__ == "__main__":
    try:
        build()
    except Exception as exc:  # noqa
        print("HATA:", exc, file=sys.stderr)
        sys.exit(1)
