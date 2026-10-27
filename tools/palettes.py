import json
import sys
from pathlib import Path

PALETTES = {
    "Warm paper": {"time": 0xF2D7B6, "date": 0x8C7B6B, "header": 0xC8643C, "body": 0xE8DCCB, "dim": 0x3A2E26},
    "Clawd": {"time": 0xF4E9DD, "date": 0x7E8794, "header": 0xD77757, "body": 0xF4E9DD, "dim": 0x34302C},
    "Night blue": {"time": 0x9FB8D8, "date": 0x4E6178, "header": 0x3C5A8A, "body": 0x9FB8D8, "dim": 0x1C2430},
}


def recolor(data, face, pal):
    w = data["width"]
    out = []
    for i, v in enumerate(data["pixels"]):
        x, y = i % w, i // w
        r, g, b = (v >> 16) & 255, (v >> 8) & 255, v & 255
        if v == 0:
            out.append(0)
        elif r > 200 and g < 60 and b < 60:
            out.append(pal["header"])
        elif r == g == b and r < 200:
            out.append(pal["dim"] if r < 120 else pal["date"])
        elif r == g == b:
            if face == "big":
                out.append(pal["date"] if y >= 11 else pal["time"])
            else:
                out.append(pal["body"] if x < 15 else pal["time"])
        else:
            out.append(v)
    return {"width": w, "height": data["height"], "pixels": out}


if __name__ == "__main__":
    shots = Path(sys.argv[1])
    for face in ("big", "sheet", "month"):
        data = json.loads((shots / f"face-{face}.json").read_text())
        for name, pal in PALETTES.items():
            slug = name.lower().replace(" ", "-")
            (shots / f"pal-{face}-{slug}.json").write_text(json.dumps(recolor(data, face, pal)))
