"""Generates the G04Passwort app icon: a glossy 3D padlock with "G04"
engraved, surrounded by a glowing neon-blue ring on a night-blue tile
(matching the design board)."""
import math
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 2048  # supersampled canvas


def lerp(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def vgrad(size, top, bottom):
    w, h = size
    g = Image.new("RGBA", size)
    d = ImageDraw.Draw(g)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=lerp(top, bottom, y / max(1, h - 1)))
    return g


def font(sz):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"]:
        try:
            return ImageFont.truetype(p, sz)
        except OSError:
            pass
    return ImageFont.load_default()


def make(opaque=False):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    # --- tile background: deep night blue with a central glow -------------
    bg = vgrad((S, S), (8, 22, 60, 255), (2, 6, 20, 255))
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([S * .18, S * .18, S * .82, S * .82], fill=(20, 110, 255, 150))
    bg = Image.alpha_composite(bg, glow.filter(ImageFilter.GaussianBlur(S * .12)))
    mask = Image.new("L", (S, S), 0)
    if opaque:
        ImageDraw.Draw(mask).rectangle([0, 0, S, S], fill=255)
    else:
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * .22), fill=255)
    img.paste(bg, (0, 0), mask)

    sc = .86 if opaque else 1.0
    cx, cy = S / 2, S / 2

    # --- neon ring --------------------------------------------------------
    R = S * .40 * sc
    ring = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse([cx - R, cy - R, cx + R, cy + R], outline=(40, 150, 255, 255), width=int(S * .035))
    img = Image.alpha_composite(img, ring.filter(ImageFilter.GaussianBlur(S * .03)))
    img = Image.alpha_composite(img, ring.filter(ImageFilter.GaussianBlur(S * .008)))
    core = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(core).ellipse([cx - R, cy - R, cx + R, cy + R], outline=(170, 225, 255, 255), width=int(S * .012))
    img = Image.alpha_composite(img, core)

    # --- shackle (metallic arc) ------------------------------------------
    bw, bh = S * .44 * sc, S * .34 * sc            # lock body size
    btop = cy - bh * .18
    sw = S * .075 * sc                              # shackle thickness
    sr = bw * .30                                   # shackle radius
    shk = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shk)
    scy = btop - sr * .55
    for i in range(14):  # layered strokes => cylindrical metallic shading
        t = i / 13
        col = lerp((70, 90, 120, 255), (235, 245, 255, 255), math.sin(t * math.pi) ** 1.5)
        w = sw * (1 - t * .9)
        o = (sw - w) / 2  # keep every layer centred on the same tube axis
        sd.arc([cx - sr + o, scy - sr + o, cx + sr - o, scy + sr - o], 180, 360, fill=col, width=max(2, int(w)))
        sd.line([(cx - sr + sw / 2, scy), (cx - sr + sw / 2, btop + 10)], fill=col, width=max(2, int(w)))
        sd.line([(cx + sr - sw / 2, scy), (cx + sr - sw / 2, btop + 10)], fill=col, width=max(2, int(w)))
    img = Image.alpha_composite(img, shk)

    # --- lock body (glossy blue-steel) -----------------------------------
    x0, y0, x1, y1 = cx - bw / 2, btop, cx + bw / 2, btop + bh
    body = vgrad((S, S), (120, 170, 230, 255), (20, 50, 120, 255))
    # shift gradient to body area
    body = vgrad((S, S), (0, 0, 0, 0), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    for y in range(int(y0), int(y1)):
        t = max(0.0, (y - y0) / bh)
        col = lerp((150, 195, 245, 255), (25, 60, 140, 255), t ** .8)
        bd.line([(x0, y), (x1, y)], fill=col)
    bmask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(bmask).rounded_rectangle([x0, y0, x1, y1], radius=int(bw * .14), fill=255)
    shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x0 + 20, y0 + 50, x1 + 20, y1 + 60], radius=int(bw * .14), fill=(0, 0, 10, 200))
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(S * .02)))
    img.paste(body, (0, 0), bmask)
    # rim + glossy highlight
    od = ImageDraw.Draw(img)
    od.rounded_rectangle([x0, y0, x1, y1], radius=int(bw * .14), outline=(200, 230, 255, 255), width=int(S * .008))
    hl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(hl).rounded_rectangle([x0 + bw * .06, y0 + bh * .05, x1 - bw * .06, y0 + bh * .32],
                                         radius=int(bw * .1), fill=(255, 255, 255, 70))
    img = Image.alpha_composite(img, hl.filter(ImageFilter.GaussianBlur(S * .006)))

    # --- "G04" engraved text ---------------------------------------------
    f = font(int(bh * .40))
    txt = "G04"
    tb = ImageDraw.Draw(img).textbbox((0, 0), txt, font=f)
    tw, th = tb[2] - tb[0], tb[3] - tb[1]
    tx, ty = cx - tw / 2 - tb[0], y0 + bh * .55 - th / 2 - tb[1]
    tl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(tl).text((tx, ty), txt, font=f, fill=(90, 200, 255, 255))
    img = Image.alpha_composite(img, tl.filter(ImageFilter.GaussianBlur(S * .012)))
    t2 = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(t2).text((tx + 6, ty + 8), txt, font=f, fill=(5, 20, 60, 220))
    ImageDraw.Draw(t2).text((tx, ty), txt, font=f, fill=(225, 245, 255, 255))
    img = Image.alpha_composite(img, t2)
    if opaque:
        img = img.convert("RGB")
    return img


if __name__ == "__main__":
    out = sys.argv[1]
    make(False).resize((1024, 1024), Image.LANCZOS).save(out + "/icon_1024.png")
    make(True).resize((1024, 1024), Image.LANCZOS).save(out + "/icon_maskable_1024.png")
    print("done")
