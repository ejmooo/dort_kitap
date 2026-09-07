#!/usr/bin/env python3
# make_icon.py: uygulama ikonunu üretir — sıcak kâğıt zemin üzerinde dört kitap
# sırtı (dört aksan renginde) ve pirinç bir raf. Tarafsız (dinî sembol yok),
# tasarım diliyle ("Mürekkep & Kâğıt") uyumlu. İki çıktı:
#   assets/icon/icon.png            (1024, tam; iOS/web/legacy)
#   assets/icon/icon_foreground.png (1024, saydam; Android adaptive ön plan)

import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "icon")
os.makedirs(OUT_DIR, exist_ok=True)

SIZE = 1024
PAPER = (245, 239, 227, 255)   # #F5EFE3
BRASS = (154, 106, 46, 255)    # #9A6A2E
BOOKS = [
    (62, 92, 138, 255),   # tevrat #3E5C8A
    (126, 90, 134, 255),  # zebur  #7E5A86
    (47, 126, 115, 255),  # incil  #2F7E73
    (92, 122, 54, 255),   # kuran  #5C7A36
]

# Merkezlenmiş taban koordinatları (dy uygulanmış).
_BARS = [
    (207, 302, 325, 754),
    (371, 254, 489, 754),
    (535, 278, 653, 754),
    (699, 292, 817, 754),
]
_SHELF = (183, 752, 841, 782)


def _scaled(box, s):
    c = SIZE / 2
    return [c + (v - c) * s for v in box]


def draw_motif(draw, scale):
    for (x0, y0, x1, y1), color in zip(_BARS, BOOKS):
        draw.rounded_rectangle(_scaled((x0, y0, x1, y1), scale),
                               radius=24 * scale, fill=color)
    draw.rounded_rectangle(_scaled(_SHELF, scale), radius=10 * scale, fill=BRASS)


def build():
    # Tam ikon: kâğıt zemin + motif.
    full = Image.new("RGBA", (SIZE, SIZE), PAPER)
    draw_motif(ImageDraw.Draw(full), 1.0)
    full.save(os.path.join(OUT_DIR, "icon.png"))

    # Adaptive ön plan: saydam zemin, güvenli alana sığması için küçültülmüş motif.
    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_motif(ImageDraw.Draw(fg), 0.66)
    fg.save(os.path.join(OUT_DIR, "icon_foreground.png"))

    print("Yazıldı:", os.path.join(OUT_DIR, "icon.png"),
          "ve icon_foreground.png")


if __name__ == "__main__":
    build()
