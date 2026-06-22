#!/usr/bin/env python3
# build_bible.py: tüm Kitab-ı Mukaddes'i (66 kitap) Türkçe (Kutsal Kitap, Yeni
# Çeviri) olarak getbible.net'ten çekip assets/data/bible.json üretir.
# Kaynak telifli ama CrossWire üzerinden dağıtım izinlidir.

import json
import os
import re
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_PATH = os.path.join(ROOT, "assets", "data", "bible.json")
BASE = "https://api.getbible.net/v2/turkish"

# Hangi kitap hangi gelenek rengini alsın (UI vurgusu için).
ROLE = {}
for n in range(1, 6):
    ROLE[n] = "tevrat"        # Yaratılış–Yasa'nın Tekrarı
ROLE[19] = "zebur"            # Mezmurlar
for n in range(40, 44):
    ROLE[n] = "incil"         # Matta, Markos, Luka, Yuhanna


def normalize(text):
    return re.sub(r"\s+", " ", (text or "")).strip()


def get(url, retries=5):
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "dort-kitap/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as exc:  # noqa
            last = exc
            time.sleep(2 * (attempt + 1))
    raise last


def build():
    books = []
    for nr in range(1, 67):
        data = get(f"{BASE}/{nr}.json")
        chapters = []
        for ch in data.get("chapters", []):
            verses = [
                {"n": v["verse"], "tr": normalize(v.get("text", ""))}
                for v in ch.get("verses", [])
            ]
            chapters.append({"n": ch.get("chapter"), "verses": verses})
        books.append({
            "nr": nr,
            "name": data.get("name", str(nr)),
            "testament": "eski" if nr <= 39 else "yeni",
            "role": ROLE.get(nr, ""),
            "chapterCount": len(chapters),
            "chapters": chapters,
        })
        print(f"  ✓ {nr:2d} {data.get('name')} ({len(chapters)} bölüm)")
        time.sleep(0.25)

    out = {
        "source": ("Türkçe: Kutsal Kitap (Yeni Çeviri) — CrossWire/getbible.net "
                   "(dağıtım izinli)"),
        "books": books,
    }
    with open(OUT_PATH, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False)
        fh.write("\n")

    total = sum(len(c["verses"]) for b in books for c in b["chapters"])
    size = os.path.getsize(OUT_PATH) / 1024 / 1024
    print(f"\nYazıldı: {OUT_PATH}  —  {len(books)} kitap, {total} ayet, {size:.2f} MB")


if __name__ == "__main__":
    build()
