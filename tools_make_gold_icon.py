#!/usr/bin/env python3
"""Create the Gold party-icon sheet from Shedinja's existing front battle art.

The Gold party renderer expects a 16x32 sheet containing two 16x16 frames.
This script selects the settled (third) frame of the credited 48x48 front art,
reduces it by the exact 3:1 integer ratio with nearest-neighbor sampling, and
stacks the result twice. It deliberately preserves source palette pixels and
alpha values without changing the supplied battle assets.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "assets" / "gen2" / "shedinja_front_3.png"
DESTINATION = ROOT / "assets" / "gen2" / "shedinja_icon.png"


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    if source.size != (48, 48):
        raise ValueError(f"Expected a 48x48 source frame, received {source.size}")

    icon = source.resize((16, 16), Image.Resampling.NEAREST)
    sheet = Image.new("RGBA", (16, 32), (255, 255, 255, 0))
    sheet.alpha_composite(icon, (0, 0))
    sheet.alpha_composite(icon, (0, 16))
    sheet.save(DESTINATION, format="PNG", optimize=False)

    result = Image.open(DESTINATION)
    if result.size != (16, 32):
        raise AssertionError(f"Unexpected icon sheet size: {result.size}")
    print(f"Wrote {DESTINATION} ({result.size[0]}x{result.size[1]})")


if __name__ == "__main__":
    main()
