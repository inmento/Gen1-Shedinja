#!/usr/bin/env python3
"""Create Shedinja's Gen 1 party-icon sheet from its credited front sprite.

The Gen 1 party renderer expects a 16x32 PNG containing two 16x16 frames. The
source Gen 1 front sprite is reduced with nearest-neighbor sampling so palette
and transparency pixels remain intact; the static result is repeated for both
engine animation frames. The source battle artwork is never modified.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "assets" / "sprites" / "shedinja_front.png"
DESTINATION = ROOT / "assets" / "sprites" / "shedinja_icon.png"


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    width, height = source.size
    if width <= 0 or height <= 0:
        raise ValueError(f"Invalid source dimensions: {source.size}")

    icon = source.resize((16, 16), Image.Resampling.NEAREST)
    sheet = Image.new("RGBA", (16, 32), (255, 255, 255, 0))
    sheet.alpha_composite(icon, (0, 0))
    sheet.alpha_composite(icon, (0, 16))
    sheet.save(DESTINATION, format="PNG", optimize=False)

    result = Image.open(DESTINATION)
    if result.size != (16, 32):
        raise AssertionError(f"Unexpected icon sheet size: {result.size}")
    print(f"Wrote {DESTINATION} from {SOURCE} ({width}x{height} -> 16x32)")


if __name__ == "__main__":
    main()
