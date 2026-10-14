"""Prepare compact loops and individual hits from the supplied recordings.

Run from any directory. Originals stay untouched; ffmpeg/ffprobe are required.
"""
import array
import hashlib
import json
import math
from pathlib import Path
import subprocess

APP = Path(__file__).resolve().parents[2]
SOURCE = APP.parent / 'sounds'
OUTPUT = APP / 'assets/sounds'
LOOPS = {
    'jungle': 'placidplace-nature-soundstropicaljunglebirds-108380.mp3',
    'night': 'freesound_community-night-ambience-17064.mp3',
    'campfire': 'soundreality-campfire-crackling-sound-439573.mp3',
    'river': 'soundsforyou-small-forest-stream-river-brook-nature-loop-111169.mp3',
    'rain': 'nematoki-night-heavy-rain-in-forest-401222.mp3',
}
HITS = {
    'wood': ('freesound_community-chopping-logs-2-24471.mp3',
             [0.28, 4.88, 6.92], 0.65),
    'step': ('freesound_community-footsteps-dirt-gravel-6823.mp3',
             [5.64, 7.42, 8.74, 10.38], 0.36),
}


def run(args):
    return subprocess.check_output(args, stderr=subprocess.PIPE)


def prepare():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = {'sources': {}, 'assets': []}
    for filename in [*LOOPS.values(), *(v[0] for v in HITS.values())]:
        source = SOURCE / filename
        manifest['sources'][filename] = {
            'path': f'../../sounds/{filename}',
            'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        }
    for name, filename in LOOPS.items():
        # Body finishes by blending into the first second. The next loop
        # starts at second one, continuing that segment rather than cutting.
        filters = (
            '[0:a]asplit=2[a][b];'
            '[a]atrim=0:1,asetpts=PTS-STARTPTS[head];'
            '[b]atrim=1:45,asetpts=PTS-STARTPTS[body];'
            '[body][head]acrossfade=d=1:c1=tri:c2=tri,'
            'loudnorm=I=-23:TP=-3:LRA=11[out]'
        )
        destination = OUTPUT / f'{name}.mp3'
        run(['ffmpeg', '-y', '-v', 'error', '-i', str(SOURCE / filename),
             '-filter_complex', filters, '-map', '[out]', '-ar', '44100',
             '-ac', '2', '-b:a', '128k', str(destination)])
        manifest['assets'].append({'file': destination.name, 'source': filename,
                                  'type': 'loop', 'sourceRange': [0, 45],
                                  'filters': filters})
    for name, (filename, starts, duration) in HITS.items():
        for index, start in enumerate(starts, 1):
            pcm = array.array('f', run([
                'ffmpeg', '-v', 'error', '-ss', str(start), '-t', str(duration),
                '-i', str(SOURCE / filename), '-ac', '1', '-ar', '44100',
                '-f', 'f32le', '-']))
            peak = max(abs(v) for v in pcm)
            gain = 20 * math.log10(0.65 / max(peak, 0.00001))
            filters = (f'volume={gain:.4f}dB,afade=t=in:d=0.005,'
                       f'afade=t=out:st={duration - .035}:d=0.035')
            destination = OUTPUT / f'{name}_{index}.wav'
            run(['ffmpeg', '-y', '-v', 'error', '-ss', str(start),
                 '-t', str(duration), '-i', str(SOURCE / filename),
                 '-af', filters, '-ac', '1', '-ar', '44100',
                 '-c:a', 'pcm_s16le', str(destination)])
            manifest['assets'].append({'file': destination.name,
                                      'source': filename, 'type': 'one-shot',
                                      'sourceRange': [start, start + duration],
                                      'filters': filters})
    for asset in manifest['assets']:
        path = OUTPUT / asset['file']
        asset['sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
        asset['bytes'] = path.stat().st_size
        asset['probe'] = json.loads(run([
            'ffprobe', '-v', 'error', '-show_entries',
            'format=duration:stream=codec_name,sample_rate,channels',
            '-of', 'json', str(path)]))
    (OUTPUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f"Prepared {len(manifest['assets'])} assets, "
          f"{sum(a['bytes'] for a in manifest['assets']) / 1024**2:.2f} MiB")


if __name__ == '__main__':
    prepare()
