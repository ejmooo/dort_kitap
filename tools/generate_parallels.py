#!/usr/bin/env python3
# generate_parallels.py: TÜM Kuran (6236 ayet) için Tevrat/Zebur/İncil paralellerini
# Claude (Anthropic API) ile üretir. Çıktı tools/ai_parallels.json'a yazılır; sonra
# `python3 tools/build_parallels.py` ile küratörlü verilerle birleştirilip
# assets/data/parallels.json üretilir.
#
# ÖNEMLİ: Üretilen paraleller YAPAY ZEKA önerisidir (origin="ai"); arayüzde
# "doğrulanmamış" uyarısıyla gösterilir. Akademik kullanım için insan denetimi şarttır.
#
# Kullanım:
#   export ANTHROPIC_API_KEY=sk-ant-...
#   python3 tools/generate_parallels.py            # tümü (kaldığı yerden devam eder)
#   python3 tools/generate_parallels.py 78 114     # yalnız 78–114 arası sûreler
#   MODEL=claude-opus-4-8 python3 tools/generate_parallels.py
#
# Maliyet/süre: 6236 ayet ~ birkaç yüz API çağrısı. Küçük aralıklarla test edin.

import json
import os
import re
import sys
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QURAN_PATH = os.path.join(ROOT, "assets", "data", "quran.json")
OUT_PATH = os.path.join(ROOT, "tools", "ai_parallels.json")
DONE_PATH = os.path.join(ROOT, "tools", ".parallels_ai_done.json")

API_URL = "https://api.anthropic.com/v1/messages"
MODEL = os.environ.get("MODEL", "claude-sonnet-4-6")
CHUNK = 15  # bir API çağrısında işlenecek ayet sayısı

SYSTEM = (
    "Sen, kutsal metinler arası karşılaştırmalı din çalışmaları konusunda dikkatli, "
    "tarafsız bir akademik asistansın. Görevin: verilen Kur'an ayetleri için, SADECE "
    "gerçekten yerleşik ve bilinen tematik/anlatısal paralelleri belirlemek. "
    "Kaynaklar yalnızca şunlardır: Tevrat (Tora: Yaratılış, Çıkış, Levililer, Çölde "
    "Sayım, Yasa'nın Tekrarı), Zebur (Mezmurlar) ve İncil (Matta, Markos, Luka, "
    "Yuhanna). Zorlama/uzak benzerlik ekleme; emin değilsen o ayet için boş liste ver. "
    "Asla 'kopya/iktibas' gibi iddialarda bulunma; yalnızca 'benzer tema' çerçevesi kullan. "
    "Çıktı KESİNLİKLE geçerli JSON olmalı, başka metin olmamalı."
)

PROMPT_TMPL = (
    "Aşağıdaki Kur'an ayetleri için paralelleri bul. Her ayet 'sure:ayet' anahtarıyla "
    "verilmiştir. Yanıtı şu biçimde, SADECE JSON olarak ver:\n"
    "{{\"sure:ayet\": [{{\"book\": \"tevrat|zebur|incil\", \"reference\": \"Türkçe kitap "
    "adı bölüm:ayet\", \"note\": \"kısa Türkçe açıklama (en fazla 12 kelime)\"}}]}}\n"
    "Paralel yoksa o anahtarı boş liste [] yap. Referans kitap adları Türkçe olmalı "
    "(ör. 'Yaratılış 1:1', 'Mezmur 23:1', 'Matta 5:21').\n\nAYETLER:\n{ayahs}"
)


def load_json(path, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    return default


def save_json(path, data):
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)


def call_claude(prompt, retries=5):
    key = os.environ.get("ANTHROPIC_API_KEY")
    if not key:
        sys.exit("HATA: ANTHROPIC_API_KEY tanımlı değil.")
    body = json.dumps({
        "model": MODEL,
        "max_tokens": 2000,
        "temperature": 0,
        "system": SYSTEM,
        "messages": [{"role": "user", "content": prompt}],
    }).encode("utf-8")
    headers = {
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    last = None
    for attempt in range(retries):
        try:
            req = urllib.request.Request(API_URL, data=body, headers=headers)
            with urllib.request.urlopen(req, timeout=120) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            return data["content"][0]["text"]
        except Exception as exc:  # noqa
            last = exc
            time.sleep(5 * (attempt + 1))
    raise last


def parse_json(text):
    text = text.strip()
    text = re.sub(r"^```(?:json)?|```$", "", text, flags=re.MULTILINE).strip()
    return json.loads(text)


def main():
    quran = load_json(QURAN_PATH, None)["surahs"]
    out = load_json(OUT_PATH, {})
    done = set(load_json(DONE_PATH, []))

    lo, hi = 1, 114
    if len(sys.argv) == 3:
        lo, hi = int(sys.argv[1]), int(sys.argv[2])

    for surah in quran:
        if not (lo <= surah["number"] <= hi):
            continue
        ayahs = [a for a in surah["ayahs"]
                 if f"{surah['number']}:{a['n']}" not in done]
        for i in range(0, len(ayahs), CHUNK):
            chunk = ayahs[i:i + CHUNK]
            listing = "\n".join(
                f"{surah['number']}:{a['n']} — {a['tr']}" for a in chunk)
            prompt = PROMPT_TMPL.format(ayahs=listing)
            try:
                result = parse_json(call_claude(prompt))
            except Exception as exc:  # noqa
                print(f"  ! {surah['number']} chunk {i} hata: {exc}")
                continue
            for a in chunk:
                key = f"{surah['number']}:{a['n']}"
                parallels = result.get(key, [])
                if parallels:
                    for p in parallels:
                        p["origin"] = "ai"
                    out[key] = parallels
                done.add(key)
            save_json(OUT_PATH, out)
            save_json(DONE_PATH, sorted(done))
            print(f"  ✓ sûre {surah['number']} [{surah['name']}] "
                  f"{i + len(chunk)}/{len(surah['ayahs'])} işlendi")
            time.sleep(0.5)

    print(f"\nBitti. Paralel bulunan ayet: {len(out)}. "
          f"Şimdi: python3 tools/build_parallels.py")


if __name__ == "__main__":
    main()
