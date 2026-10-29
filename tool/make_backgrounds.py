"""Procedurally renders the G04Passwort night-landscape backgrounds
(blue-glow mountains under a starry sky) used behind the glass UI."""
import math
import random
import sys
from PIL import Image, ImageDraw, ImageFilter

W, H = 1170, 2532


def lerp(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def ridge(seed, base, amp, rough):
    """Jagged mountain silhouette via midpoint displacement."""
    rnd = random.Random(seed)
    n = 257
    ys = [0.0] * n
    ys[0], ys[-1] = rnd.uniform(-.5, .5), rnd.uniform(-.5, .5)
    step, scale = n - 1, 1.0
    while step > 1:
        half = step // 2
        for i in range(half, n, step):
            ys[i] = (ys[i - half] + ys[i + half]) / 2 + rnd.uniform(-scale, scale)
        step, scale = half, scale * .55
    # two dominant peaks
    p1, p2 = rnd.uniform(.15, .4), rnd.uniform(.6, .85)
    pts = []
    for i, y in enumerate(ys):
        x = i / (n - 1)
        peak = max(1 - abs(x - p1) * 3.2, 0) ** 1.3 + .8 * max(1 - abs(x - p2) * 3.6, 0) ** 1.3
        pts.append((x * W, base - amp * (peak * 1.4 + y * .45)))
    return pts


def render(seed, sky_top, sky_mid, glow_col, layers, out):
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=lerp(sky_top, sky_mid, t * 1.6) if t < .62 else lerp(sky_mid, (2, 4, 12), (t - .62) * 2.6))
    # stars
    rnd = random.Random(seed)
    stars = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stars)
    for _ in range(900):
        x, y = rnd.random() * W, rnd.random() * H * .55
        r = rnd.choice([1, 1, 1, 1.5, 2])
        a = rnd.randint(60, 230)
        sd.ellipse([x - r, y - r, x + r, y + r], fill=(220, 235, 255, a))
    img.paste(stars, (0, 0), stars)
    # horizon glow
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([-W * .3, H * .30, W * 1.3, H * .62], fill=glow_col + (150,))
    img.paste(glow.filter(ImageFilter.GaussianBlur(160)), (0, 0), glow.filter(ImageFilter.GaussianBlur(160)))
    # mountain layers (back to front)
    for i, (base, amp, col, rim) in enumerate(layers):
        pts = ridge(seed + i * 13, H * base, H * amp, 1.2)
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        ld.polygon(pts + [(W, H), (0, H)], fill=col + (255,))
        ld.line(pts, fill=rim + (255,), width=3)
        rimglow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(rimglow).line(pts, fill=rim + (200,), width=14)
        rimglow = rimglow.filter(ImageFilter.GaussianBlur(18))
        img.paste(rimglow, (0, 0), rimglow)
        img.paste(layer, (0, 0), layer)
    # mist at the bottom
    mist = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    for y in range(int(H * .6), H):
        md.line([(0, y), (W, y)], fill=(3, 6, 16, int(255 * min(1, (y - H * .6) / (H * .3)))))
    img.paste(mist, (0, 0), mist)
    img.save(out, quality=82, optimize=True)


if __name__ == "__main__":
    o = sys.argv[1]
    render(4, (2, 6, 22), (10, 40, 110), (30, 110, 255),
           [(.42, .10, (10, 26, 66), (70, 150, 255)),
            (.50, .08, (6, 16, 44), (40, 110, 220)),
            (.58, .06, (3, 9, 26), (25, 80, 180))], o + "/bg_mountains.jpg")
    render(11, (4, 2, 24), (40, 20, 110), (120, 70, 255),
           [(.46, .09, (18, 12, 60), (150, 110, 255)),
            (.56, .06, (8, 6, 32), (90, 70, 220))], o + "/bg_nebula.jpg")
    render(23, (1, 10, 22), (6, 60, 90), (0, 200, 230),
           [(.44, .11, (6, 30, 50), (60, 220, 255)),
            (.55, .07, (3, 16, 30), (30, 150, 200))], o + "/bg_polar.jpg")
    print("ok")
