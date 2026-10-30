"""Extracts the app artwork from the original G04Passwort design files.

Sources (docs/design):
  * design_board.png – screen design board (mountain backgrounds)
  * asset_sheet.png  – asset sheet (app icon, logo, splash, backgrounds,
                       3D lock, 16 feature icons, extra backgrounds)

Usage:  pip install pillow numpy scipy && python3 tool/extract_design_assets.py

Coordinates refer to the 1254x1254 sheets; higher resolution exports with
the same layout are scaled automatically. Dedicated high-res files can also
simply be copied over the generated assets (same file names).
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / "docs/design"
REF = 1254

SHEET_ICONS = {
    # row 1
    "passwords": (28, 790, 118, 877), "generator": (148, 790, 235, 877),
    "security": (262, 790, 350, 877), "cards": (376, 790, 464, 877),
    "documents": (489, 790, 578, 877), "notes": (606, 790, 694, 877),
    "cloud": (721, 790, 810, 877), "settings": (837, 790, 923, 877),
    # row 2
    "biometric": (28, 925, 118, 1012), "search": (148, 925, 235, 1012),
    "folder": (262, 925, 350, 1012), "favorites": (376, 925, 464, 1012),
    "tags": (489, 925, 578, 1012), "totp": (606, 925, 694, 1012),
    "import_export": (721, 925, 810, 1012), "analysis": (837, 925, 923, 1012),
}

SHEET_BACKGROUNDS = {
    "bg_login.jpg": (24, 492, 449, 727),
    "bg_dashboard.jpg": (471, 492, 831, 727),
    "bg_splash.jpg": (856, 420, 1233, 650),
    "bg_earth.jpg": (23, 1094, 220, 1227),
    "bg_waves.jpg": (234, 1094, 400, 1227),
    "bg_shield.jpg": (414, 1094, 613, 1227),
    "bg_flow.jpg": (625, 1094, 770, 1227),
    "bg_circuit.jpg": (782, 1094, 938, 1227),
    "bg_hex.jpg": (951, 1094, 1059, 1227),
    "bg_curve.jpg": (1072, 1094, 1234, 1227),
}

BOARD_BACKGROUNDS = {
    "bg_mountains.jpg": (225, 0, 520, 86),
    "bg_summit.jpg": (1040, 150, 1254, 288),
}


def up(img, scale):
    size = (round(img.width * scale), round(img.height * scale))
    return img.resize(size, Image.LANCZOS).filter(
        ImageFilter.UnsharpMask(radius=2, percent=70, threshold=2))


def loader(name):
    im = Image.open(DESIGN / name).convert("RGB")
    f = im.width / REF
    return lambda box: im.crop(tuple(round(v * f) for v in box)), f


def remove_dark_background(rgb):
    """Makes the dark background connected to the image border transparent
    (removes the painted checkerboard of the logo)."""
    arr = np.array(rgb).astype(int)
    bright = arr.max(2)
    lab, _ = ndimage.label(bright < 72)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    fg = ~np.isin(lab, list(border))
    flab, fn = ndimage.label(fg)
    idx = range(1, fn + 1)
    sizes = ndimage.sum(np.ones_like(bright), flab, idx)
    means = ndimage.mean(bright, flab, idx)
    keep = np.zeros(fn + 1, bool)
    for i, (s, m) in enumerate(zip(sizes, means), 1):
        keep[i] = s > 2000 or m > 110
    fg = keep[flab]
    # Remove dim glow fragments (painted checkerboard behind the glow) that
    # touch the transparent background; the dark shield interior is
    # enclosed by the bright rim and therefore kept.
    dim = fg & (bright < 115)
    dlab, dn = ndimage.label(dim)
    touching = ndimage.binary_dilation(~fg, iterations=2) & dim
    for i in set(np.unique(dlab[touching])) - {0}:
        fg[dlab == i] = False
    alpha = Image.fromarray(np.where(fg, 255, 0).astype("uint8")).filter(ImageFilter.GaussianBlur(0.8))
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def radial_fade(rgb):
    """Soft circular alpha so the 3D lock blends into any dark background."""
    w, h = rgb.size
    y, x = np.ogrid[:h, :w]
    d = np.sqrt(((x - w / 2) / (w / 2)) ** 2 + ((y - h / 2) / (h / 2)) ** 2)
    alpha = np.clip((1.0 - d) / 0.25, 0, 1) * 255
    out = rgb.convert("RGBA")
    out.putalpha(Image.fromarray(alpha.astype("uint8")))
    return out


def main():
    (ROOT / "assets/icons").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets/images").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets/branding").mkdir(parents=True, exist_ok=True)

    crop, f = loader("asset_sheet.png")
    k = 1 / f  # normalise to the 1254 reference
    logo = remove_dark_background(crop((386, 50, 810, 412)))  # without slogan
    up(logo, 2 * k).save(ROOT / "assets/branding/logo.png")
    # App icon = logo (shield + "G04 Passwort") on the night-blue backdrop.
    yy, xx = np.mgrid[0:1024, 0:1024]
    # Bright neon-blue glow behind the shield (as on the design board) so the
    # icon reads clearly on dark and light home screens.
    d = np.clip(np.sqrt((xx - 512) ** 2 + (yy - 440) ** 2) / 560, 0, 1) ** 0.9
    chans = [(a * (1 - d) + b * d).astype("uint8") for a, b in [(30, 6), (120, 22), (255, 70)]]
    bg = Image.merge("RGB", [Image.fromarray(ch) for ch in chans]).convert("RGBA")
    mark = up(logo, 1)
    mark = mark.crop(mark.getchannel("A").getbbox())  # drop transparent margins
    # Large logo, but clear of the rounded corners iOS/Android cut away.
    scale = min(900 / mark.width, 900 / mark.height)
    mark = mark.resize((round(mark.width * scale), round(mark.height * scale)), Image.LANCZOS)
    bg.alpha_composite(mark, ((1024 - mark.width) // 2, (1024 - mark.height) // 2))
    bg.convert("RGB").save(ROOT / "assets/branding/app_icon.png")
    shield = logo.crop((0, 0, logo.width, round(logo.height * 0.66)))
    up(shield, 2 * k).save(ROOT / "assets/branding/logo_mark.png")
    lock = radial_fade(crop((935, 695, 1215, 1055)))
    up(lock, 2 * k).save(ROOT / "assets/branding/lock_3d.png")
    for name, box in SHEET_ICONS.items():
        up(crop(box), 3 * k).save(ROOT / f"assets/icons/ic_{name}.png")
    for name, box in SHEET_BACKGROUNDS.items():
        img = crop(box)
        up(img, max(1, 1600 / img.width)).save(ROOT / f"assets/images/{name}", quality=90)

    crop, f = loader("design_board.png")
    for name, box in BOARD_BACKGROUNDS.items():
        img = crop(box)
        up(img, max(1, 1600 / img.width)).save(ROOT / f"assets/images/{name}", quality=90)
    print("Design assets extracted.")


if __name__ == "__main__":
    main()
