"""Extracts the app artwork (app icon, backgrounds, feature icons) from the
original G04Passwort design board (docs/design/design_board.png).

Usage: python3 tool/extract_design_assets.py
Replace docs/design/design_board.png with a higher resolution export (same
layout, any size) and re-run to get sharper assets.
"""
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
BOARD = ROOT / "docs/design/design_board.png"
REF = 1254  # coordinates below refer to the 1254x1254 board

FEATURES = {
    "aes": (530, 27, 612, 96), "biometric": (635, 27, 717, 96),
    "cloud": (737, 27, 820, 96), "twofa": (840, 27, 922, 96),
    "autolock": (941, 27, 1023, 96), "generator": (530, 158, 612, 227),
    "autosave": (635, 158, 717, 227), "securitycheck": (737, 158, 820, 227),
    "cards": (840, 158, 922, 227), "documents": (941, 158, 1023, 227),
}


def main():
    im = Image.open(BOARD).convert("RGB")
    f = im.width / REF

    def crop(box):
        return im.crop(tuple(round(v * f) for v in box))

    def up(img, size):
        return img.resize(size, Image.LANCZOS).filter(
            ImageFilter.UnsharpMask(radius=2, percent=80, threshold=2))

    up(crop((16, 16, 232, 232)), (1024, 1024)).save(ROOT / "assets/branding/app_icon.png")
    up(crop((225, 0, 520, 86)), (1180, 344)).save(ROOT / "assets/images/bg_mountains.jpg", quality=92)
    up(crop((1040, 150, 1254, 288)), (856, 552)).save(ROOT / "assets/images/bg_summit.jpg", quality=92)
    for name, box in FEATURES.items():
        w, h = box[2] - box[0], box[3] - box[1]
        up(crop(box), (w * 3, h * 3)).save(ROOT / f"assets/icons/feat_{name}.png")
    print("Design assets extracted.")


if __name__ == "__main__":
    main()
