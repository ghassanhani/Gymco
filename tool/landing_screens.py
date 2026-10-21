"""The five hero phones for gymcoapp.com, in both looks, from the app itself.

    SHOTS=1 flutter test test/shots/landing_shots_test.dart --update-goldens
    python3 tool/landing_screens.py

Reads test/shots/out/landing-<look>-<slot>.png (1170 x 2532, a phone at 3x),
draws a status bar into the space the app leaves for it, and writes
site/img/landing/screen-<slot>.jpg (dark) and screen-<slot>-light.jpg at
660 x 1434, the size the page draws them.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "test/shots/out"
OUT = ROOT / "site/img/landing"
SLOTS = ["today", "l1", "l2", "r1", "r2"]
INK = {"light": (16, 18, 14), "dark": (245, 247, 240)}
W, H = 660, 1434


def status_bar(im: Image.Image, color) -> None:
    """21:45 on the left; signal, wifi and battery on the right (iPhone layout at 3x)."""
    d = ImageDraw.Draw(im)
    font = ImageFont.truetype(str(ROOT / "assets/fonts/Urbanist-Bold.ttf"), 50)
    cy = 76
    d.text((200, cy), "21:45", font=font, fill=color, anchor="mm")
    x = 870
    # Signal: four bars of rising height.
    for i in range(4):
        h = 12 + i * 8
        d.rounded_rectangle((x + i * 15, cy + 18 - h, x + i * 15 + 10, cy + 18), 3, fill=color)
    # Wifi: three arcs and a dot.
    wx, wy = 975, cy + 16
    for r in (34, 23, 12):
        d.arc((wx - r, wy - r, wx + r, wy + r), 225, 315, fill=color, width=7)
    d.ellipse((wx - 5, wy - 9, wx + 5, wy + 1), fill=color)
    # Battery: outline, fill and nub.
    bx = 1030
    d.rounded_rectangle((bx, cy - 17, bx + 72, cy + 17), 9, outline=color, width=4)
    d.rounded_rectangle((bx + 7, cy - 10, bx + 52, cy + 10), 5, fill=color)
    d.rounded_rectangle((bx + 76, cy - 6, bx + 82, cy + 6), 3, fill=color)


def fit(im: Image.Image) -> Image.Image:
    """Scale to cover 660 x 1434, trimming the long side from the middle."""
    s = max(W / im.width, H / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    x, y = (im.width - W) // 2, (im.height - H) // 2
    return im.crop((x, y, x + W, y + H))


def main() -> None:
    for look in ("dark", "light"):
        for slot in SLOTS:
            im = Image.open(SRC / f"landing-{look}-{slot}.png").convert("RGB")
            status_bar(im, INK[look])
            name = f"screen-{slot}.jpg" if look == "dark" else f"screen-{slot}-light.jpg"
            fit(im).save(OUT / name, quality=86, optimize=True, progressive=True)
            print("wrote", name)


if __name__ == "__main__":
    main()
