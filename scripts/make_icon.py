#!/usr/bin/env python3
"""
WinMac app icon generator.

Concept: "Windows habits on a Mac." A macOS Big Sur squircle in a Windows-blue
gradient with a 2x2 "Snap Layout" of windows on top — the first tile is a macOS
window (traffic lights), the others carry a Windows-style maximise glyph.
Rendered at 4x then downscaled for clean edges.

Outputs:
  Resources/AppIcon_1024.png
  Resources/AppIcon.icns   (via a temporary .iconset + iconutil)
"""
import os
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "Resources")

S = 4                                  # supersample factor
CANVAS = 1024 * S
BODY = 856 * S                         # squircle side (Apple icon grid)
PAD = (CANVAS - BODY) // 2
RADIUS = int(BODY * 0.225)

ACCENT = (92, 206, 255)                # bright cyan


def vgradient(size, top, bottom):
    w, h = size
    col = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / (h - 1)
        col.putpixel((0, y), tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return col.resize((w, h))


def glass_window(canvas, box, title_dots=False, fill=90, tbar=0.20):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    r = int(min(w, h) * 0.13)
    stroke = int(4.4 * S)

    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle(
        [x0 - stroke, y0 - stroke, x1 + stroke, y1 + stroke],
        radius=r + stroke, outline=ACCENT + (210,), width=stroke)
    canvas.alpha_composite(glow.filter(ImageFilter.GaussianBlur(11 * S)))

    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.rounded_rectangle(box, radius=r, fill=(150, 190, 225, fill))
    tb = y0 + int(h * tbar)
    ld.rounded_rectangle([x0, y0, x1, tb], radius=r, fill=(212, 233, 250, min(255, fill + 60)))
    ld.rectangle([x0, y0 + r, x1, tb], fill=(212, 233, 250, min(255, fill + 60)))
    ld.rounded_rectangle(box, radius=r, outline=ACCENT + (255,), width=stroke)
    ld.rounded_rectangle([x0 + stroke, y0 + stroke, x1 - stroke, y1 - stroke],
                         radius=max(1, r - stroke), outline=(255, 255, 255, 65), width=max(1, S))
    canvas.alpha_composite(layer)

    d = ImageDraw.Draw(canvas)
    if title_dots:
        dot_r = int(h * 0.028)
        cy = y0 + int(h * tbar / 2)
        cx = x0 + int(w * 0.13)
        gap = int(dot_r * 3.2)
        for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
            d.ellipse([cx + i * gap - dot_r, cy - dot_r, cx + i * gap + dot_r, cy + dot_r], fill=c + (255,))
    else:
        gy = y0 + int(h * tbar / 2)
        gx = x1 - int(w * 0.12)
        s = int(h * 0.030)
        d.rounded_rectangle([gx - s, gy - s, gx + s, gy + s], radius=max(1, S * 2),
                            outline=(255, 255, 255, 210), width=max(2, int(1.6 * S)))


def build():
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))

    # squircle mask on the Apple grid
    mask = Image.new("L", (CANVAS, CANVAS), 0)
    ImageDraw.Draw(mask).rounded_rectangle([PAD, PAD, CANVAS - PAD, CANVAS - PAD],
                                           radius=RADIUS, fill=255)

    # contact shadow
    sh = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([PAD, PAD + int(14 * S), CANVAS - PAD, CANVAS - PAD + int(14 * S)],
                                         radius=RADIUS, fill=(0, 0, 0, 120))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(18 * S)))

    # gradient body
    body = vgradient((CANVAS, CANVAS), (32, 56, 104), (10, 16, 32)).convert("RGBA")
    canvas.paste(body, (0, 0), mask)

    # top sheen
    sheen = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ImageDraw.Draw(sheen).rounded_rectangle([PAD, PAD, CANVAS - PAD, CANVAS // 2],
                                            radius=RADIUS, fill=(255, 255, 255, 16))
    sheen = sheen.filter(ImageFilter.GaussianBlur(46 * S))
    canvas.alpha_composite(Image.composite(sheen, Image.new("RGBA", canvas.size, (0, 0, 0, 0)), mask))

    # 2x2 snap grid
    m = PAD + int(BODY * 0.11)
    gap = int(BODY * 0.036)
    cx, cy = CANVAS // 2, CANVAS // 2
    tl = (m, m, cx - gap // 2, cy - gap // 2)
    tr = (cx + gap // 2, m, CANVAS - m, cy - gap // 2)
    bl = (m, cy + gap // 2, cx - gap // 2, CANVAS - m)
    br = (cx + gap // 2, cy + gap // 2, CANVAS - m, CANVAS - m)
    for box in (tr, bl, br):
        glass_window(canvas, box, fill=66)
    glass_window(canvas, tl, title_dots=True, fill=110)

    # clip anything that bled past the squircle
    canvas = Image.composite(canvas, Image.new("RGBA", canvas.size, (0, 0, 0, 0)),
                             mask.point(lambda v: 255))  # keep full canvas; windows sit inside anyway

    out = canvas.resize((1024, 1024), Image.Resampling.LANCZOS)
    png = os.path.join(RES, "AppIcon_1024.png")
    out.save(png)
    print("wrote", png)

    iconset = os.path.join(RES, "AppIcon.iconset")
    if os.path.isdir(iconset):
        shutil.rmtree(iconset)
    os.makedirs(iconset)
    for base, scale in [(16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
                        (256, 1), (256, 2), (512, 1), (512, 2)]:
        px = base * scale
        canvas.resize((px, px), Image.Resampling.LANCZOS).save(
            os.path.join(iconset, f"icon_{base}x{base}{'@2x' if scale == 2 else ''}.png"))
    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", os.path.join(RES, "AppIcon.icns")], check=True)
    shutil.rmtree(iconset)
    print("wrote", os.path.join(RES, "AppIcon.icns"))


if __name__ == "__main__":
    build()
