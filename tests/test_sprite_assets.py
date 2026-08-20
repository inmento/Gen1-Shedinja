from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
expected_gen1 = {
    'shedinja_front.png': (56, 56),
    'shedinja_back.png': (48, 48),
    'shedinja_back_potato_voxel.png': (48, 48),
    'shedinja_icon.png': (16, 32),
}
for name, size in expected_gen1.items():
    image = Image.open(root / 'assets' / 'sprites' / name).convert('RGBA')
    assert image.size == size, f'{name}: expected {size}, got {image.size}'
    alpha = [pixel[3] for pixel in image.getdata()]
    assert min(alpha) == 0, f'{name}: missing transparent background'
    assert max(alpha) == 255, f'{name}: missing opaque sprite pixels'

back = Image.open(root / 'assets' / 'sprites' / 'shedinja_back.png').convert('RGBA')
potato_back = Image.open(root / 'assets' / 'sprites' / 'shedinja_back_potato_voxel.png').convert('RGBA')
assert list(back.transpose(Image.Transpose.FLIP_LEFT_RIGHT).getdata()) == list(potato_back.getdata()), \
    'Potato Voxel helper asset must remain an exact horizontal mirror of its legacy source art'

icon = Image.open(root / 'assets' / 'sprites' / 'shedinja_icon.png').convert('RGBA')
assert list(icon.crop((0, 0, 16, 16)).getdata()) == list(icon.crop((0, 16, 16, 32)).getdata()), \
    'Gen 1 Shedinja icon must repeat its static image in both party-animation frames'

expected_gold = {
    'shedinja_front_1.png': (48, 48),
    'shedinja_front_2.png': (48, 48),
    'shedinja_front_3.png': (48, 48),
    'shedinja_back.png': (48, 48),
    'shedinja_icon.png': (16, 32),
}
valid_shades = {0, 85, 170, 255}
for name, size in expected_gold.items():
    image = Image.open(root / 'assets' / 'gen2' / name).convert('RGBA')
    assert image.size == size, f'Gold {name}: expected {size}, got {image.size}'
    opaque = [pixel for pixel in image.getdata() if pixel[3] == 255]
    assert opaque, f'Gold {name}: missing opaque sprite pixels'
    assert all(pixel[0] == pixel[1] == pixel[2] for pixel in opaque), \
        f'Gold {name}: sprite must remain grayscale for palette-based shiny support'
    assert {pixel[0] for pixel in opaque}.issubset(valid_shades), \
        f'Gold {name}: contains a non-indexed grayscale shade'

print('sprite asset tests passed')
