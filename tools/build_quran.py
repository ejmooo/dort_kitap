#!/usr/bin/env python3
# build_quran.py: tüm Kuran metnini (114 sûre / 6236 ayet) Arapça (Uthmânî) +
# Türkçe meal (Elmalılı Hamdi Yazır, kamu malı) olarak çekip assets/data/quran.json
# üretir. Her iki metin de tek istekle alınır (alquran.cloud).

import json
import os
import re
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_PATH = os.path.join(ROOT, "assets", "data", "quran.json")

AR_URL = "https://api.alquran.cloud/v1/quran/quran-uthmani"
TR_URL = "https://api.alquran.cloud/v1/quran/tr.yazir"

# Sûrelerin Türkçe adları (1..114).
SURAH_NAMES_TR = [
    "Fâtiha", "Bakara", "Âl-i İmrân", "Nisâ", "Mâide", "En'âm", "A'râf", "Enfâl",
    "Tevbe", "Yûnus", "Hûd", "Yûsuf", "Ra'd", "İbrâhîm", "Hicr", "Nahl", "İsrâ",
    "Kehf", "Meryem", "Tâhâ", "Enbiyâ", "Hac", "Mü'minûn", "Nûr", "Furkân",
    "Şuarâ", "Neml", "Kasas", "Ankebût", "Rûm", "Lokmân", "Secde", "Ahzâb",
    "Sebe'", "Fâtır", "Yâsîn", "Sâffât", "Sâd", "Zümer", "Mü'min", "Fussilet",
    "Şûrâ", "Zuhruf", "Duhân", "Câsiye", "Ahkâf", "Muhammed", "Fetih", "Hucurât",
    "Kâf", "Zâriyât", "Tûr", "Necm", "Kamer", "Rahmân", "Vâkıa", "Hadîd",
    "Mücâdele", "Haşr", "Mümtehine", "Saff", "Cumâ", "Münâfikûn", "Tegâbün",
    "Talâk", "Tahrîm", "Mülk", "Kalem", "Hâkka", "Meâric", "Nûh", "Cin",
    "Müzzemmil", "Müddessir", "Kıyâme", "İnsân", "Mürselât", "Nebe'", "Nâziât",
    "Abese", "Tekvîr", "İnfitâr", "Mutaffifîn", "İnşikâk", "Bürûc", "Târık",
    "A'lâ", "Gâşiye", "Fecr", "Beled", "Şems", "Leyl", "Duhâ", "İnşirâh", "Tîn",
    "Alak", "Kadir", "Beyyine", "Zilzâl", "Âdiyât", "Kâria", "Tekâsür", "Asr",
    "Hümeze", "Fîl", "Kureyş", "Mâûn", "Kevser", "Kâfirûn", "Nasr", "Tebbet",
    "İhlâs", "Felâk", "Nâs",
]

BASMALA_SKELETON = ["بسم", "الله", "الرحمن", "الرحيم"]
_HARAKAT = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭـ]")


def _skeleton(word):
    return _HARAKAT.sub("", word).replace("ٱ", "ا")


def strip_basmala(text):
    words = text.split()
    if len(words) >= 4 and [_skeleton(w) for w in words[:4]] == BASMALA_SKELETON:
        return " ".join(words[4:])
    return text


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "dort-kitap/1.0"})
    with urllib.request.urlopen(req, timeout=90) as resp:
        return json.loads(resp.read().decode("utf-8"))["data"]


def build():
    print("Arapça (Uthmânî) çekiliyor...")
    ar = get(AR_URL)
    print("Türkçe meal (Elmalılı) çekiliyor...")
    tr = get(TR_URL)

    surahs = []
    for s_ar, s_tr in zip(ar["surahs"], tr["surahs"]):
        num = s_ar["number"]
        ayahs = []
        for a_ar, a_tr in zip(s_ar["ayahs"], s_tr["ayahs"]):
            n = a_ar["numberInSurah"]
            text_ar = " ".join(a_ar["text"].split())
            # Fâtiha (1) ve Tevbe (9) hariç ilk ayetteki Besmele önekini at.
            if n == 1 and num not in (1, 9):
                text_ar = strip_basmala(text_ar)
            ayahs.append({
                "n": n,
                "g": a_ar["number"],  # Kuran genelinde 1..6236 (ses CDN'i için)
                "ar": text_ar,
                "tr": " ".join(a_tr["text"].split()),
            })
        surahs.append({
            "number": num,
            "name": SURAH_NAMES_TR[num - 1],
            "ayahCount": len(ayahs),
            "ayahs": ayahs,
        })

    out = {
        "source": ("Arapça: Kur'an-ı Kerim (Uthmânî hat) · Türkçe meal: Elmalılı "
                   "Hamdi Yazır — alquran.cloud (kamu malı metinler)"),
        "surahs": surahs,
    }
    with open(OUT_PATH, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False)
        fh.write("\n")

    total = sum(len(s["ayahs"]) for s in surahs)
    size = os.path.getsize(OUT_PATH) / 1024 / 1024
    print(f"Yazıldı: {OUT_PATH}  —  {len(surahs)} sûre, {total} ayet, {size:.2f} MB")


if __name__ == "__main__":
    build()
