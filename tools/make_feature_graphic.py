#!/usr/bin/env python3
# make_feature_graphic.py: Google Play "öne çıkan görsel"ini (1024×500) üretir.
# Renkler ve amblem uygulamadaki Atlas tasarımından alınır:
#   - amblem geometrisi: lib/widgets/atlas_motion.dart › _AtlasPainter
#   - koyu yeşil zemin: Keşfet kartındaki degrade
# Fontlar projeyle birlikte gelen değişken fontlardır (assets/fonts).
#
# Kullanım:  python3 tools/make_feature_graphic.py
# Çıktı:     docs/store/feature-graphic.png

import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "store", "feature-graphic.png")
FONTS = os.path.join(ROOT, "assets", "fonts")

W, H = 1024, 500
SS = 3  # süper örnekleme: büyük çiz, küçült → kenar yumuşatma

TOP_LEFT = (0x24, 0x4C, 0x41)
BOTTOM_RIGHT = (0x12, 0x2E, 0x27)
CREAM = (0xF7, 0xEF, 0xE2)
PEACH = (0xF2, 0xBF, 0x91)
SAGE = (0xB9, 0xDB, 0xC8)
# _AtlasPainter'daki sıra ile aynı.
EMBLEM = [(0xF2, 0xBF, 0x91), (0xC7, 0xB7, 0xF0), (0xAA, 0xD5, 0xCD), (0xEA, 0xE3, 0xB0)]


def font(name, size, weight):
    f = ImageFont.truetype(os.path.join(FONTS, name), size * SS)
    try:
        # Değişken fontun ağırlık eksenini ayarla (Lora 400–700, Manrope 200–800).
        f.set_variation_by_axes([weight])
    except (OSError, AttributeError):
        pass  # FreeType değişken font desteği yoksa varsayılan ağırlık
    return f


def gradient(w, h):
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / w * 0.55 + y / h * 0.45)
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TOP_LEFT, BOTTOM_RIGHT))
    return img


def ellipse_points(cx, cy, rx, ry, angle, n=360):
    ca, sa = math.cos(angle), math.sin(angle)
    pts = []
    for i in range(n + 1):
        t = 2 * math.pi * i / n
        x, y = rx * math.cos(t), ry * math.sin(t)
        pts.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return pts


def draw_emblem(draw, cx, cy, size):
    stroke = max(1, round(size / 85))
    for i, color in enumerate(EMBLEM):
        pts = ellipse_points(cx, cy, size * 0.43 / 2, size * 0.88 / 2, i * math.pi / 4)
        draw.line(pts, fill=color, width=stroke, joint="curve")
    r = size * 0.035
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PEACH)


def tracked(draw, xy, text, fnt, fill, tracking):
    """Harf aralıklı metin (kicker stili)."""
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += draw.textlength(ch, font=fnt) + tracking


def main():
    img = gradient(W * SS, H * SS)
    d = ImageDraw.Draw(img)

    # Sağda büyük amblem, hafifçe kenardan taşarak.
    draw_emblem(d, 800 * SS, 250 * SS, 360 * SS)

    left = 72 * SS
    tracked(d, (left, 118 * SS), "OKUMA ATLASI", font("Manrope-Variable.ttf", 22, 700),
            PEACH, 4.5 * SS)
    d.text((left, 150 * SS), "Dört Kitap", font=font("Lora-Variable.ttf", 104, 700), fill=CREAM)
    d.text((left, 296 * SS), "Tevrat · Zebur · İncil · Kur’an",
           font=font("Manrope-Variable.ttf", 30, 600), fill=SAGE)
    d.text((left, 344 * SS), "Ortak konular, yan yana.",
           font=font("Manrope-Variable.ttf", 30, 400), fill=SAGE)

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    img.resize((W, H), Image.LANCZOS).save(OUT, optimize=True)
    print("yazıldı:", OUT)


if __name__ == "__main__":
    main()
