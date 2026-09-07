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
#   MODEL=claude-opus-5 python3 tools/generate_parallels.py
#   CHUNK=8 python3 tools/generate_parallels.py    # çağrı başına daha az ayet
#
# Kesinti/devam: her başarılı çağrıdan sonra ilerleme tools/ai_parallels.json ve
# tools/.parallels_ai_done.json dosyalarına ATOMİK olarak yazılır. Ctrl-C, kopma,
# rate-limit veya çökme sonrası AYNI komutu tekrar çalıştırmak yeterlidir; işlenmiş
# ayetler atlanır. Sıfırdan başlamak için .parallels_ai_done.json'u silin.
#
# Maliyet/süre: 6236 ayet ~ birkaç yüz API çağrısı. Küçük aralıklarla test edin.

import json
import os
import random
import re
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QURAN_PATH = os.path.join(ROOT, "assets", "data", "quran.json")
OUT_PATH = os.path.join(ROOT, "tools", "ai_parallels.json")
DONE_PATH = os.path.join(ROOT, "tools", ".parallels_ai_done.json")

API_URL = "https://api.anthropic.com/v1/messages"
MODEL = os.environ.get("MODEL", "claude-sonnet-4-6")
CHUNK = int(os.environ.get("CHUNK", "15"))  # bir API çağrısında işlenecek ayet sayısı
MAX_TOKENS = 4000
RETRIES = 6
# Art arda bu kadar hata olursa dur: genelde anahtar/kota/model sorunudur ve
# devam etmek 114 sûre boyunca boşuna hata basmaktan başka işe yaramaz.
MAX_CONSECUTIVE_FAILURES = 5

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


class ApiError(RuntimeError):
    """Yeniden denenmesi anlamsız olan API hatası."""


def load_json(path, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    return default


def save_json(path, data):
    """Atomik yazma: önce .tmp dosyasına yaz, fsync'le, sonra yerine taşı.

    Doğrudan yazarken Ctrl-C/çökme araya girerse dosya yarım kalır ve o ana kadarki
    TÜM ilerleme okunamaz hale gelir. os.replace aynı dizinde atomiktir.
    """
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
        fh.flush()
        os.fsync(fh.fileno())
    os.replace(tmp, path)


def _retry_after(headers, fallback):
    """429/529 yanıtındaki retry-after başlığına uy; yoksa kendi beklememizi kullan."""
    raw = headers.get("retry-after") if headers else None
    if raw:
        try:
            return max(1.0, float(raw))
        except (TypeError, ValueError):
            pass
    return fallback


def call_claude(prompt, retries=RETRIES):
    key = os.environ.get("ANTHROPIC_API_KEY")
    if not key:
        sys.exit("HATA: ANTHROPIC_API_KEY tanımlı değil.")
    body = json.dumps({
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "temperature": 0,
        "system": SYSTEM,
        "messages": [{"role": "user", "content": prompt}],
    }).encode("utf-8")
    headers = {
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    }
    delay = 2.0
    last = None
    for attempt in range(retries):
        wait = delay
        try:
            req = urllib.request.Request(API_URL, data=body, headers=headers)
            with urllib.request.urlopen(req, timeout=180) as resp:
                data = json.loads(resp.read().decode("utf-8"))
            if data.get("stop_reason") == "max_tokens":
                # Yanıt yarıda kesilmiş: JSON zaten parse edilemez. Tekrar denemek
                # aynı sonucu verir; CHUNK küçültülmeli.
                raise ApiError("yanıt max_tokens sınırına takıldı — CHUNK değerini düşürün")
            return data["content"][0]["text"], data.get("usage", {})
        except ApiError:
            raise
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", "replace")[:300]
            last = ApiError(f"HTTP {exc.code}: {detail}")
            # 429 rate limit, 529 overloaded, 5xx geçici → beklenip tekrar denenir.
            # 400/401/403/404 kalıcıdır (geçersiz anahtar, kota, model adı): hemen çık.
            if exc.code < 500 and exc.code not in (408, 409, 429):
                raise last
            wait = _retry_after(exc.headers, delay)
        except Exception as exc:  # noqa: BLE001 — ağ kopması, timeout, bozuk JSON
            last = exc
        if attempt == retries - 1:
            break
        time.sleep(wait + random.uniform(0, 1))  # jitter: eşzamanlı yeniden denemeleri dağıtır
        delay = min(delay * 2, 60)
    raise last


def parse_json(text):
    text = text.strip()
    text = re.sub(r"^```(?:json)?|```$", "", text, flags=re.MULTILINE).strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # Modelin araya yazdığı açıklama metnini at, ilk { ile son } arasını dene.
        start, end = text.find("{"), text.rfind("}")
        if start == -1 or end <= start:
            raise
        return json.loads(text[start:end + 1])


def main():
    quran = load_json(QURAN_PATH, None)["surahs"]
    out = load_json(OUT_PATH, {})
    done = set(load_json(DONE_PATH, []))

    lo, hi = 1, 114
    if len(sys.argv) == 3:
        lo, hi = int(sys.argv[1]), int(sys.argv[2])

    scope = [s for s in quran if lo <= s["number"] <= hi]
    total = sum(len(s["ayahs"]) for s in scope)
    todo = sum(1 for s in scope for a in s["ayahs"]
               if f"{s['number']}:{a['n']}" not in done)
    print(f"Model: {MODEL} | sûre {lo}-{hi} | {total} ayet, {total - todo} zaten işlenmiş, "
          f"{todo} kaldı (~{-(-todo // CHUNK)} API çağrısı)")
    if not todo:
        print("Yapılacak bir şey yok.")
        return

    fails = 0
    failed_total = 0
    processed = 0
    tok_in = tok_out = 0
    started = time.time()

    try:
        for surah in scope:
            ayahs = [a for a in surah["ayahs"]
                     if f"{surah['number']}:{a['n']}" not in done]
            for i in range(0, len(ayahs), CHUNK):
                chunk = ayahs[i:i + CHUNK]
                listing = "\n".join(
                    f"{surah['number']}:{a['n']} — {a['tr']}" for a in chunk)
                prompt = PROMPT_TMPL.format(ayahs=listing)
                try:
                    text, usage = call_claude(prompt)
                    result = parse_json(text)
                except KeyboardInterrupt:
                    raise
                except Exception as exc:  # noqa: BLE001
                    fails += 1
                    failed_total += len(chunk)
                    print(f"  ! {surah['number']}:{chunk[0]['n']} hata "
                          f"({fails}/{MAX_CONSECUTIVE_FAILURES}): {exc}")
                    if fails >= MAX_CONSECUTIVE_FAILURES:
                        print("\nArt arda çok fazla hata — durduruldu. İlerleme kaydedildi; "
                              "sorunu giderip aynı komutu tekrar çalıştırın.")
                        return
                    continue
                fails = 0
                tok_in += usage.get("input_tokens", 0)
                tok_out += usage.get("output_tokens", 0)
                for a in chunk:
                    key = f"{surah['number']}:{a['n']}"
                    parallels = result.get(key, [])
                    if parallels:
                        for p in parallels:
                            p["origin"] = "ai"
                        out[key] = parallels
                    done.add(key)
                # Sıralama önemli: önce sonuç, sonra "işlendi" işareti. Tersi olursa
                # aradaki bir çökme ayeti bir daha hiç işlenmemek üzere done'a yazar.
                save_json(OUT_PATH, out)
                save_json(DONE_PATH, sorted(done))
                processed += len(chunk)
                rate = processed / max(time.time() - started, 1e-6)
                eta = (todo - processed) / rate / 60 if rate else 0
                print(f"  ✓ sûre {surah['number']} [{surah['name']}] "
                      f"{i + len(chunk)}/{len(surah['ayahs'])} | "
                      f"toplam {processed}/{todo} | ~{eta:.0f} dk kaldı")
                time.sleep(0.5)
    except KeyboardInterrupt:
        print("\nDurduruldu (Ctrl-C). İlerleme kaydedildi; aynı komutla kaldığı "
              "yerden devam eder.")
        return
    finally:
        print(f"\nBu oturumda {processed} ayet işlendi | "
              f"token: {tok_in} girdi / {tok_out} çıktı | "
              f"paralel bulunan toplam ayet: {len(out)}")

    if failed_total:
        print(f"{failed_total} ayet hata nedeniyle atlandı — aynı komutu tekrar "
              f"çalıştırın, yalnızca eksikler işlenir.")
    else:
        print("Bitti. Şimdi: python3 tools/build_parallels.py")


if __name__ == "__main__":
    main()
