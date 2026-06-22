#!/usr/bin/env python3
# build_parallels.py: ayet düzeyinde benzerlik indeksini (assets/data/parallels.json)
# üretir. İki kaynağı birleştirir:
#   1) Küratörlü/kaynaklı paraleller  -> tools/seed.json'daki temalardan türetilir
#      (origin="curated", arayüzde "doğrulanmış" rozetiyle gösterilir)
#   2) Yapay zeka önerileri           -> tools/ai_parallels_sample.json (+ ileride
#      tools/generate_parallels.py çıktısı) (origin="ai", "doğrulanmamış" uyarısıyla)
# Çıktı "sure:ayet" anahtarlı bir sözlüktür.

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_themes import tr_reference  # noqa: E402  (İngilizce->Türkçe referans)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEED_PATH = os.path.join(ROOT, "tools", "seed.json")
AI_SAMPLE_PATH = os.path.join(ROOT, "tools", "ai_parallels_sample.json")
AI_FULL_PATH = os.path.join(ROOT, "tools", "ai_parallels.json")  # generate_parallels.py çıktısı
OUT_PATH = os.path.join(ROOT, "assets", "data", "parallels.json")

BIBLE_BOOKS = ("tevrat", "zebur", "incil")


def expand_ayahs(ref):
    """'112:1-4' -> ['112:1','112:2','112:3','112:4']; '2:153' -> ['2:153']."""
    surah, ayahs = ref.split(":")
    if "-" in ayahs:
        start, end = ayahs.split("-")
        return [f"{surah}:{i}" for i in range(int(start), int(end) + 1)]
    return [f"{surah}:{ayahs}"]


def add(index, key, parallel):
    bucket = index.setdefault(key, [])
    # Aynı (kitap, referans) ikilisini iki kez ekleme.
    if not any(p["book"] == parallel["book"] and p["reference"] == parallel["reference"]
               for p in bucket):
        bucket.append(parallel)


def load_curated(index):
    with open(SEED_PATH, encoding="utf-8") as fh:
        seed = json.load(fh)
    count = 0
    for theme in seed:
        refs = theme["refs"]
        if "kuran" not in refs:
            continue
        others = []
        for book in BIBLE_BOOKS:
            if book in refs:
                others.append({
                    "book": book,
                    "reference": tr_reference(refs[book]),
                    "note": theme["title"],
                    "origin": "curated",
                    "themeId": theme["id"],
                })
        for key in expand_ayahs(refs["kuran"]):
            for parallel in others:
                add(index, key, dict(parallel))
                count += 1
    return count


def load_ai(index, path):
    if not os.path.exists(path):
        return 0
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    count = 0
    for key, parallels in data.items():
        if key.startswith("_"):  # _comment vb. atla
            continue
        for parallel in parallels:
            entry = dict(parallel)
            entry.setdefault("origin", "ai")
            add(index, key, entry)
            count += 1
    return count


def build():
    index = {}
    c = load_curated(index)
    a1 = load_ai(index, AI_SAMPLE_PATH)
    a2 = load_ai(index, AI_FULL_PATH)

    ordered = {k: index[k] for k in sorted(index, key=lambda x: (int(x.split(":")[0]), int(x.split(":")[1])))}
    with open(OUT_PATH, "w", encoding="utf-8") as fh:
        json.dump(ordered, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    print(f"Yazıldı: {OUT_PATH}")
    print(f"  küratörlü paralel: {c} · ai örnek: {a1} · ai tam: {a2}")
    print(f"  benzerlik içeren ayet sayısı: {len(ordered)}")


if __name__ == "__main__":
    build()
