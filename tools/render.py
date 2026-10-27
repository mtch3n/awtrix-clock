import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

CELL = 12
DOT = 9
PAD = 24
LABEL_H = 30


def frame_image(pixels, width, height):
    img = Image.new("RGB", (width * CELL + 16, height * CELL + 16), (14, 14, 16))
    d = ImageDraw.Draw(img)
    for y in range(height):
        for x in range(width):
            v = pixels[y * width + x]
            rgb = ((v >> 16) & 255, (v >> 8) & 255, v & 255)
            if rgb == (0, 0, 0):
                rgb = (28, 28, 32)
            x0 = 8 + x * CELL + (CELL - DOT) // 2
            y0 = 8 + y * CELL + (CELL - DOT) // 2
            d.ellipse([x0, y0, x0 + DOT, y0 + DOT], fill=rgb)
    return img


def main(out, items):
    tiles = []
    for label, path in items:
        data = json.loads(Path(path).read_text())
        tiles.append((label, frame_image(data["pixels"], data["width"], data["height"])))
    cols = 2
    tw, th = tiles[0][1].size
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (PAD + cols * (tw + PAD), PAD + rows * (th + LABEL_H + PAD)), (32, 32, 36))
    d = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=18)
    for i, (label, img) in enumerate(tiles):
        x = PAD + (i % cols) * (tw + PAD)
        y = PAD + (i // cols) * (th + LABEL_H + PAD)
        d.text((x, y), label, fill=(230, 230, 235), font=font)
        sheet.paste(img, (x, y + LABEL_H))
    sheet.save(out)


if __name__ == "__main__":
    args = sys.argv[2:]
    main(sys.argv[1], [(args[i], args[i + 1]) for i in range(0, len(args), 2)])
