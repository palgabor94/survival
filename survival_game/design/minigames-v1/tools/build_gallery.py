#!/usr/bin/env python3
"""Build a self-contained, local review gallery from exported PNG previews."""
import html
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
files = (root / 'screens/manifest.txt').read_text().splitlines()
titles = {'chopping': 'Favágás', 'foraging': 'Növénygyűjtés', 'hunting': 'Vadászat'}
labels = {
    'ready': 'Indítás', 'active': 'Játék közben', 'perfect': 'Tökéletes időzítés',
    'miss': 'Elhibázott mozdulat', 'result': 'Sikeres eredmény',
    'failure-result': 'Sikertelen eredmény', 'risky-result': 'Kockázatos növény eredménye',
    'timeout': 'Idő lejárt', 'selected': 'Kiválasztott növény', 'page-two': 'További növények / eszközkapu',
    'pause': 'Szünet', 'leave': 'Kilépés megerősítése', 'locked': 'Hiányzó eszköz',
    'small-phone': 'Kisebb mobil · 375 × 812', 'landscape': 'Fekvő nézet · 844 × 390',
    'large-text': 'Nagy betűk · 150%',
}
screens = []
for name in files:
    number, game, state = name[:-4].split('-', 2)
    screens.append({'file': 'screens/' + name, 'game': game, 'state': state,
                    'label': labels[state], 'number': number,
                    'adaptive': state in ('small-phone', 'landscape', 'large-text')})
assets = json.loads((root / 'manifest.json').read_text())['assets']
overview = ''.join(
    f'<article><h2>{title}</h2><button class="shot" data-overview="{game}" aria-label="{title} terveinek megnyitása">'
    f'<img src="{next(s["file"] for s in screens if s["game"] == game and s["state"] == "active")}" alt="{title} – játék közbeni látványterv" width="780" height="1688"></button></article>'
    for game, title in titles.items())
asset_labels = {'wood_chopping_background_v1': 'Favágó tisztás',
                'foraging_background_v1': 'Növényliget', 'hunting_background_v1': 'Vadászösvény',
                'mushroom_card_scene_v1': 'Gomba · kártyakép',
                'unknown_plant_card_scene_v1': 'Ismeretlen növény · kártyakép',
                'hunting_boar_sprite_v2': 'Vaddisznó · átlátszó sprite'}
asset_html = ''.join(
    f'<a class="asset {a["kind"]}" href="assets/{a["name"]}.png" target="_blank" rel="noopener">'
    f'<img loading="lazy" src="assets/{a["name"]}.png" alt="{html.escape(asset_labels[a["name"]])}" width="{a["dimensions"][0]}" height="{a["dimensions"][1]}">'
    f'<span>{html.escape(asset_labels[a["name"]])}</span></a>' for a in assets)
template = '''<!doctype html>
<html lang="hu"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lost Canopy · minijáték látványtervek</title>
<style>
:root{color-scheme:dark;--bg:#102a28;--panel:#202e29;--cream:#fff0cc;--gold:#f0c773;--muted:#c8cbb5;--border:#8f926f}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--cream);font:16px/1.5 Arial,sans-serif}
main{max-width:1220px;margin:auto;padding:32px 24px 72px}h1{font-size:30px;margin:0 0 12px}h2{font-size:20px;margin:0 0 12px}p{color:var(--muted);max-width:820px}
a{color:var(--gold)}a:focus-visible,button:focus-visible,input:focus-visible{outline:3px solid var(--gold);outline-offset:4px}
button{cursor:pointer;font:inherit;color:inherit;border:1px solid var(--border);border-radius:10px;background:var(--panel);min-height:48px;padding:10px 16px}
button:hover{background:#354337}button[aria-pressed=true]{background:#bbd987;color:#203f2b;border-color:#bbd987}button:disabled{opacity:.55;cursor:default}
.links{display:flex;flex-wrap:wrap;gap:16px;margin:20px 0 28px}.overview{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;margin:28px 0 48px}
.shot{display:block;padding:0;border:0;background:transparent;overflow:hidden;border-radius:18px;max-width:340px}
.shot img{display:block;width:100%;height:auto}.controls{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0}.adaptive{display:flex;align-items:center;gap:10px;min-height:48px;color:var(--muted)}input{width:22px;height:22px}
.review{display:grid;grid-template-columns:minmax(260px,420px) 1fr;gap:28px;align-items:start;margin-bottom:48px}
.review figure{margin:0}.review img{display:block;width:100%;height:auto;border-radius:18px}.review figcaption{margin:12px 0;color:var(--muted)}.states{display:grid;gap:8px}.states button{text-align:left}.states small{display:block;color:var(--muted)}
.arrows{display:flex;gap:10px;margin-top:16px}.arrows button{flex:1}.status{color:var(--gold)}.assets{display:grid;grid-template-columns:repeat(3,1fr);gap:18px}
.asset{display:block;border:1px solid var(--border);border-radius:14px;overflow:hidden;text-decoration:none;background:var(--panel)}.asset img{display:block;width:100%;height:auto}.asset span{display:block;padding:12px;color:var(--cream)}
.asset.background img{max-height:500px;object-fit:contain}.asset.sprite img{background:repeating-conic-gradient(#354337 0% 25%,#202e29 0% 50%) 50%/24px 24px}
@media(max-width:700px){main{padding:24px 16px 48px}.overview{gap:12px}.overview h2{font-size:14px}.review{grid-template-columns:1fr}.review figure{max-width:420px;margin:auto}.states{grid-template-columns:repeat(2,1fr)}.assets{grid-template-columns:repeat(2,1fr)}}
@media(prefers-reduced-motion:reduce){*{scroll-behavior:auto}}
</style>
<main>
<h1>Lost Canopy · minijáték látványtervek</h1>
<p>Favágás, növénygyűjtés és vadászat. Új, eltérő helyszínek az egységes karakterrel és izometrikus kamerával; a meglévő játék UI-jából renderelt tervek.</p>
<p>Tervezési előnézet. A jutalmak példaértékek; a játékfolyamat implementációja ezután következik.</p>
<nav class="links" aria-label="Csomagfájlok"><a href="DESIGN.md">Részletes terv és állapotátmenetek</a><a href="PROMPTS.md">Generálási promptok</a><a href="manifest.json">Képfájlok</a><a href="validation.json">Ellenőrzés</a></nav>
<section class="overview" aria-label="A három fő képernyő">__OVERVIEW__</section>
<h2>Állapotok és popupok</h2>
<div class="controls" id="games" role="group" aria-label="Minijáték"><button data-game="chopping" aria-pressed="true">Favágás</button><button data-game="foraging" aria-pressed="false">Növénygyűjtés</button><button data-game="hunting" aria-pressed="false">Vadászat</button></div>
<label class="adaptive"><input id="adaptive" type="checkbox">Kisebb mobil, fekvő nézet és nagy betűs tervek is látszódjanak</label>
<section class="review" aria-label="Látványterv böngésző">
<figure><a id="full" href="screens/02-chopping-active.png" target="_blank" rel="noopener"><img id="selected" src="screens/02-chopping-active.png" alt="Favágás – játék közben" width="780" height="1688"></a><figcaption id="caption" aria-live="polite"></figcaption><div class="arrows"><button id="prev">Előző</button><button id="next">Következő</button></div></figure>
<div><p class="status" id="count"></p><div class="states" id="states" role="group" aria-label="Képernyőállapotok"></div></div>
</section>
<h2>Generált hátterek és képelemek</h2>
<p>Három teljes háttér, két 3:2 kártyaillusztráció és egy külön, átlátszó vaddisznó.</p>
<section class="assets" aria-label="Generált képek">__ASSETS__</section>
</main>
<script>
const screens=__SCREENS__,titles=__TITLES__;
let game='chopping',selected=screens.find(s=>s.game===game&&s.state==='active');
const $=id=>document.getElementById(id);
function available(){return screens.filter(s=>s.game===game&&(!s.adaptive||$('adaptive').checked))}
function render(){const list=available();if(!list.includes(selected))selected=list[0];$('states').replaceChildren();
for(const item of list){const b=document.createElement('button');b.textContent=item.number+' · '+item.label;b.setAttribute('aria-pressed',String(item===selected));b.onclick=()=>{selected=item;render()};$('states').append(b)}
$('selected').src=selected.file;$('selected').alt=titles[game]+' – '+selected.label;$('full').href=selected.file;$('caption').textContent=titles[game]+' · '+selected.label+' · teljes PNG megnyitásához kattints a képre.';$('count').textContent=list.length+' terv ehhez a minijátékhoz';
document.querySelectorAll('[data-game]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.game===game)));$('prev').disabled=list.indexOf(selected)===0;$('next').disabled=list.indexOf(selected)===list.length-1}
function pickGame(value){game=value;selected=screens.find(s=>s.game===game&&s.state==='active');render()}
document.querySelectorAll('[data-game]').forEach(b=>b.onclick=()=>pickGame(b.dataset.game));
document.querySelectorAll('[data-overview]').forEach(b=>b.onclick=()=>{pickGame(b.dataset.overview);$('games').scrollIntoView()});
function step(delta){const list=available();selected=list[Math.max(0,Math.min(list.length-1,list.indexOf(selected)+delta))];render()}
$('prev').onclick=()=>step(-1);$('next').onclick=()=>step(1);$('adaptive').onchange=render;
document.addEventListener('keydown',e=>{if(e.target.tagName==='INPUT')return;if(e.key==='ArrowLeft'){e.preventDefault();step(-1)}if(e.key==='ArrowRight'){e.preventDefault();step(1)}});render();
</script></html>
'''
output = (template.replace('__OVERVIEW__', overview).replace('__ASSETS__', asset_html)
          .replace('__SCREENS__', json.dumps(screens, ensure_ascii=False))
          .replace('__TITLES__', json.dumps(titles, ensure_ascii=False)))
(root / 'index.html').write_text(output)
(root / 'screens/manifest.json').write_text(json.dumps(screens, ensure_ascii=False, indent=2) + '\n')
print(f'Gallery built: {len(screens)} screens, {len(assets)} selected assets.')
