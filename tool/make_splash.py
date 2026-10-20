"""Draws the launch-screen logo: the Gymco G filled with the Volt glow
(lime to mint, as VLogo paints it) on a transparent ground, at every size the
iOS launch screen and Android splash need.

    python3 tool/make_splash.py
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MASK = Image.open(ROOT / "assets/brand/logo-mask.png").convert("RGBA")
STOPS = [(0.0, (0xE4, 0xFF, 0x6A)), (0.45, (0xB6, 0xF0, 0x2A)), (1.0, (0x5E, 0xE4, 0xA0))]


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def glow(size):
    """Volt.glow: a linear gradient from (-0.8,-0.6) to (0.8,0.6) of the box."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    ax, ay, bx, by = 0.1 * size, 0.2 * size, 0.9 * size, 0.8 * size
    dx, dy = bx - ax, by - ay
    d2 = dx * dx + dy * dy
    for y in range(size):
        for x in range(size):
            t = max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / d2))
            for (t0, c0), (t1, c1) in zip(STOPS, STOPS[1:]):
                if t <= t1:
                    px[x, y] = lerp(c0, c1, (t - t0) / (t1 - t0))
                    break
    return img


def logo(size, canvas=None):
    """The G at [size] px, centred on a transparent [canvas] px square."""
    canvas = canvas or size
    g = glow(size).convert("RGBA")
    g.putalpha(MASK.resize((size, size), Image.LANCZOS).getchannel("A"))
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.paste(g, ((canvas - size) // 2, (canvas - size) // 2), g)
    return out


# iOS: 96 pt in the launch screen.
ios = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
for scale, name in [(1, "LaunchImage.png"), (2, "LaunchImage@2x.png"), (3, "LaunchImage@3x.png")]:
    logo(96 * scale).save(ios / name, optimize=True)

# Android up to 11: 96 dp centred on ink (launch_background.xml).
# Android 12+: the splash icon is a 288 dp square whose middle 192 dp shows;
# the G sits at 96 dp inside it so it matches the older look and the app.
res = ROOT / "android/app/src/main/res"
for dpi, k in [("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2), ("xxhdpi", 3), ("xxxhdpi", 4)]:
    d = res / f"drawable-{dpi}"
    d.mkdir(exist_ok=True)
    logo(round(96 * k)).save(d / "splash_logo.png", optimize=True)
    logo(round(96 * k), round(288 * k)).save(d / "splash_icon.png", optimize=True)
print("splash images written")
