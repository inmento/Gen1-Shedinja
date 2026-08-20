#!/usr/bin/env python3
"""Create the Gen 1 Shedinja back asset pre-mirrored for Potato Voxel.

Potato Voxel mirrors the player Pokémon card in staged 3D battles. Supplying
this image only to Potato Voxel's player-back resolver produces the credited
back sprite in its original orientation after Potato's own mirror transform.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
source = ROOT / "assets" / "sprites" / "shedinja_back.png"
target = ROOT / "assets" / "sprites" / "shedinja_back_potato_voxel.png"

with Image.open(source) as image:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    image.transpose(Image.Transpose.FLIP_LEFT_RIGHT).save(target)

print(target)
