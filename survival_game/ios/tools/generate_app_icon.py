#!/usr/bin/env python3
"""Package the approved artwork into the existing iOS AppIcon slots."""
import json
from pathlib import Path
import struct
import subprocess

project = Path(__file__).resolve().parents[2]
source = project / 'design/app-icon-v1/lost_canopy_explorer_icon_v1.png'
folder = project / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
images = json.loads((folder / 'Contents.json').read_text())['images']
sizes = {}
for entry in images:
    width, height = map(float, entry['size'].split('x'))
    scale = int(entry['scale'].removesuffix('x'))
    size = round(width * scale)
    if width != height or (entry['filename'] in sizes and sizes[entry['filename']] != size):
        raise ValueError('Inconsistent AppIcon slot')
    sizes[entry['filename']] = size
for filename, size in sizes.items():
    output = folder / filename
    subprocess.run(['sips', '-z', str(size), str(size), str(source), '--out', str(output)],
                   check=True, stdout=subprocess.DEVNULL)
    png = output.read_bytes()
    if png[:8] != b'\x89PNG\r\n\x1a\n' or struct.unpack('>II', png[16:24]) != (size, size):
        raise ValueError(f'Incorrect PNG size: {filename}')
    if png[25] != 2:
        raise ValueError(f'AppIcon must be RGB without an alpha channel: {filename}')
print(f'Generated and validated {len(sizes)} RGB PNGs for {len(images)} iOS AppIcon slots.')
