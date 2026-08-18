#!/usr/bin/env python3
"""Prepare user-provided Shedinja art as transparent Gen 1 battle sprite PNGs.

This is a deterministic fallback used after AI background removal did not preserve
single-sprite framing. It removes only the connected pale background region reached
from the image border, then downscales with nearest-neighbour sampling.
"""
from __future__ import annotations

from collections import Counter, deque
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
UPLOADS = Path('/home/ubuntu/upload')
ASSETS = ROOT / 'assets' / 'sprites'

# The provided full-size PNG is the front sprite; the artist-provided JPEG is the back.
SOURCES = {
    'shedinja_front.png': (UPLOADS / 'dkxmmx8-136525e3-638e-48a5-8e9b-d8c1bc76d56a.png', 56),
    'shedinja_back.png': (UPLOADS / 'g1sp_0292___shedinja_by_bouncingpiplup_dkxmmx8-375w-2x.jpg', 48),
}


def border_mode(pixels: list[tuple[int, int, int, int]], width: int, height: int) -> tuple[int, int, int, int]:
    border = []
    for x in range(width):
        border.extend((pixels[x], pixels[(height - 1) * width + x]))
    for y in range(1, height - 1):
        border.extend((pixels[y * width], pixels[y * width + (width - 1)]))
    return Counter(border).most_common(1)[0][0]


def distance(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> int:
    return sum((a[i] - b[i]) ** 2 for i in range(3))


def remove_connected_background(image: Image.Image, tolerance: int) -> Image.Image:
    image = image.convert('RGBA')
    width, height = image.size
    pixels = list(image.getdata())
    background = border_mode(pixels, width, height)
    limit = tolerance * tolerance
    cleared = [False] * (width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        i = y * width + x
        if not cleared[i] and distance(pixels[i], background) <= limit:
            cleared[i] = True
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(1, height - 1):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < width and 0 <= ny < height:
                enqueue(nx, ny)

    out = []
    for i, pixel in enumerate(pixels):
        out.append((pixel[0], pixel[1], pixel[2], 0 if cleared[i] else pixel[3]))
    image.putdata(out)
    return image


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    for name, (source, size) in SOURCES.items():
        if not source.is_file():
            raise FileNotFoundError(source)
        # The PNG background is exact; the JPEG needs a modest tolerance for compression.
        tolerance = 8 if source.suffix.lower() == '.png' else 36
        sprite = remove_connected_background(Image.open(source), tolerance)
        sprite = sprite.resize((size, size), Image.Resampling.NEAREST)
        target = ASSETS / name
        sprite.save(target, 'PNG')
        print(f'{source.name} -> {target.name} ({size}x{size})')


if __name__ == '__main__':
    main()
