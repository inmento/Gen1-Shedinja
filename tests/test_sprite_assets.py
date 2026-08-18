from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
expected = {
    'shedinja_front.png': (56, 56),
    'shedinja_back.png': (48, 48),
}
for name, size in expected.items():
    image = Image.open(root / 'assets' / 'sprites' / name).convert('RGBA')
    assert image.size == size, f'{name}: expected {size}, got {image.size}'
    alpha = [pixel[3] for pixel in image.getdata()]
    assert min(alpha) == 0, f'{name}: missing transparent background'
    assert max(alpha) == 255, f'{name}: missing opaque sprite pixels'
print('sprite asset tests passed')
