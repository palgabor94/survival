#!/usr/bin/env python3
"""Build local galleries from exported native screenshots and artwork registries."""
import hashlib
import html
import json
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[2]
CSS = '''body{margin:0;background:#102926;color:#fff3d0;font:16px Arial,sans-serif}
main{max-width:1600px;margin:auto;padding:24px}h1{font-size:28px}p{line-height:1.6}
a{color:#c9e394}nav{display:flex;gap:20px;flex-wrap:wrap;margin:24px 0}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}
figure{margin:0;background:#1c3630;padding:12px;border-radius:12px}
figcaption{margin-bottom:12px;font-weight:bold}img{display:block;width:100%;height:auto}
.icons img{height:140px;object-fit:contain}.art img{max-height:700px;object-fit:contain}
'''


def figures(entries):
    return '\n'.join(
        f'<figure><figcaption>{html.escape(label)}</figcaption>'
        f'<a href="{html.escape(path)}"><img loading="lazy" src="{html.escape(path)}" '
        f'alt="{html.escape(label)}"></a></figure>' for path, label in entries
    )


def write_gallery(name, title, description, *, extras=''):
    directory = ROOT / 'screenshots' / name
    manifest_file = directory / 'manifest.txt'
    if manifest_file.exists():
        files = manifest_file.read_text().splitlines()
    else:
        files = [file.name for file in sorted(directory.glob('[0-9][0-9]-*.png'))]
        manifest_file.write_text('\n'.join(files) + '\n')
    entries = [(file, file.removesuffix('.png').replace('-', ' ')) for file in files]
    manifest = []
    for file in files:
        data = (directory / file).read_bytes()
        manifest.append(dict(file=file, dimensions=list(struct.unpack('>II', data[16:24])),
                             sha256=hashlib.sha256(data).hexdigest()))
    (directory / 'capture_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (directory / 'index.html').write_text(
        '<!doctype html><html lang="hu"><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        f'<title>{html.escape(title)}</title><style>{CSS}</style><main>'
        f'<h1>{html.escape(title)}</h1><p>{html.escape(description)}</p>'
        '<nav><a href="../camp-variants-v2/index.html">9 táborváltozat</a>'
        '<a href="../rescue-milestone-v1/index.html">32 rescue kép</a>'
        '<a href="../card-illustrations-v1/index.html">42 kártyakép</a>'
        '<a href="../unified-ui-v1/index.html">30 mobilképernyő</a></nav>'
        f'<div class="grid">{figures(entries)}</div>{extras}</main></html>\n'
    )


camp_rows = json.loads((ROOT / 'assets/art/camp_variants_manifest_v2.json').read_text())
write_gallery('camp-variants-v2', 'Lost Canopy · 9 shelter-változat',
              'Tier 1–3: tűz, ágy, munkaasztal. Valódi Flutter UI, 390 × 844 logikai méret, '
              '780 × 1688 PNG. Nappali nyugalomban 30 másodperces váltás, 650 ms áttűnés.',
              extras='<h2>Teljes háttérképek</h2><div class="grid art">' + figures([
                  ('../../assets/art/' + row['file'], f"Tier {row['tier']} · {row['pose']}")
                  for row in camp_rows]) + '</div>')

icons = json.loads((ROOT / 'assets/art/item_icon_manifest_v1.json').read_text())['icons']
write_gallery('rescue-milestone-v1', 'Lost Canopy · megmentési mérföldkő',
              '32 sorrendbe tett natív Flutter-képernyő: alkatrészek, romok, puzzle, beacon, '
              'jeladás, vihar és megmentés. A 19. és 20. kép külön átlátszó itemikonokat használ.',
              extras='<h2>Átlátszó itemikonok</h2><div class="grid icons">' + figures([
                  ('../../' + row['file'], row['id'].replace('_', ' '))
                  for row in icons]) + '</div>')

subjects = re.findall(r"'([^']+)'", (ROOT / 'lib/ui/card_illustration.dart').read_text().split('];')[0])
write_gallery('card-illustrations-v1', 'Lost Canopy · 42 kártyaillusztráció',
              '4 natív Flutter-kártyalap; 42 saját hátteres, középre komponált 3:2 illusztráció. '
              'Egységes soronkénti magasság és legfeljebb 160 px álló kártyaszélesség.',
              extras='<h2>Külön illusztrációk</h2><div class="grid art">' + figures([
                  (f'../../assets/art/card_{subject}_scene_v1.png', subject.replace('_', ' '))
                  for subject in subjects]) + '</div>')
print('Updated camp, rescue and card galleries, including capture hashes.')
