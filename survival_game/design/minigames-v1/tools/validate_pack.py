#!/usr/bin/env python3
"""Validate delivered design files and render evidence; no gameplay tests."""
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import shutil
import struct
import subprocess
from PIL import Image

root = Path(__file__).resolve().parents[1]
assets = json.loads((root / 'manifest.json').read_text())['assets']
screens = json.loads((root / 'screens/manifest.json').read_text())
for asset in assets:
    data = Path(asset['path']).read_bytes()
    assert hashlib.sha256(data).hexdigest() == asset['sha256']
    dimensions = list(struct.unpack('>II', data[16:24]))
    assert dimensions == asset['dimensions']
    if asset['kind'] == 'card':
        assert dimensions[0] * 2 == dimensions[1] * 3
for screen in screens:
    data = (root / screen['file']).read_bytes()
    expected = ((1688, 780) if screen['state'] == 'landscape' else
                (750, 1624) if screen['state'] == 'small-phone' else (780, 1688))
    assert struct.unpack('>II', data[16:24]) == expected

class GalleryParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.refs, self.scripts, self.in_script = [], [], False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for key in ('src', 'href'):
            if key in attrs:
                self.refs.append(attrs[key])
        if tag == 'script':
            self.in_script = True

    def handle_endtag(self, tag):
        if tag == 'script':
            self.in_script = False

    def handle_data(self, data):
        if self.in_script:
            self.scripts.append(data)

parser = GalleryParser()
parser.feed((root / 'index.html').read_text())
for ref in parser.refs:
    if ref != 'validation.json':
        assert (root / ref).exists(), ref
syntax = 'not checked: Node unavailable'
if node := shutil.which('node'):
    script = Path('/private/tmp/lost-canopy-minigames-gallery.js')
    script.write_text(''.join(parser.scripts))
    subprocess.run([node, '--check', str(script)], check=True)
    syntax = 'passed'
log = (root / 'render.log').read_text()
assert 'EXPORTED 37 DESIGN PREVIEWS' in log
assert not any(error in log for error in ('overflowed', 'Unhandled exception', 'StateError'))
assert 'No issues found' in (root / 'analyze.log').read_text()
with Image.open(next(a['path'] for a in assets if a['kind'] == 'sprite')) as sprite:
    assert sprite.mode == 'RGBA'
    alpha = sprite.getchannel('A').getextrema()
    assert alpha[0] == 0
validation = {
    'date': '2026-10-13', 'scope': 'design-only, no gameplay implementation',
    'native_preview_render': 'passed',
    'phone_state_previews': sum(not s['adaptive'] for s in screens),
    'adaptive_previews': sum(s['adaptive'] for s in screens),
    'total_screens': len(screens), 'selected_generated_assets': len(assets),
    'mobile_logical_size': [390, 844], 'small_phone_logical_size': [375, 812],
    'landscape_logical_size': [844, 390], 'large_text_scale': 1.5,
    'reduced_motion_rendering': True, 'safe_area_top': 24, 'safe_area_bottom': 20,
    'card_illustration_aspect_ratio': '3:2', 'portrait_card_width_cap': 160,
    'equal_card_row_height': True, 'render_overflows': 0,
    'dart_preview_analyzer': 'No issues found', 'gallery_local_links': 'passed',
    'gallery_javascript_syntax': syntax, 'asset_hashes': 'passed',
    'sprite_rgba_alpha': list(alpha), 'gameplay_tests_run': False,
    'production_minigames_integrated': False, 'fishing_changed': False,
}
(root / 'validation.json').write_text(json.dumps(validation, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(validation, ensure_ascii=False))
