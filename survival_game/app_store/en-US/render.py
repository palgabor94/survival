#!/usr/bin/env python3
"""Render isolated UI concepts with the existing native Flutter engine."""
import os
from pathlib import Path
import shutil
import subprocess

project = Path(__file__).resolve().parents[2]
os.chdir(project)
sdk = Path('/private/tmp/lost-canopy-flutter-sdk')
engines = sdk / 'bin/cache/artifacts/engine'
engine = engines / 'darwin-x64'
if not engine.exists():
    engine = engines / 'darwin-arm64'
output = project / '.dart_tool/app_store_en.dill'
log = project / '.dart_tool/app-store-en-compile.log'
args = [str(sdk / 'bin/cache/dart-sdk/bin/dartaotruntime'),
        str(engine / 'frontend_server_aot.dart.snapshot'),
        '--sdk-root', str(engines / 'common/flutter_patched_sdk') + '/',
        '--target=flutter', '--enable-asserts', '--no-print-incremental-dependencies',
        '--packages=.dart_tool/package_config.json', '--output-dill', str(output),
        'app_store/en-US/render.dart']
with log.open('w') as stream:
    status = subprocess.run(args, stdout=stream, stderr=subprocess.STDOUT).returncode
if status or not output.exists() or 'Error:' in log.read_text():
    print(log.read_text())
    raise SystemExit(status or 1)
assets = project / 'build/unit_test_assets'
assets.mkdir(parents=True, exist_ok=True)
shutil.copytree(project / 'assets', assets / 'assets', dirs_exist_ok=True)
env = os.environ.copy()
env['FLUTTER_ROOT'] = str(sdk)
env['FLUTTER_TEST'] = 'true'
args = [str(engine / 'flutter_tester'), '--disable-vm-service',
        '--enable-checked-mode', '--enable-software-rendering',
        '--skia-deterministic-rendering', '--use-test-fonts',
        '--disable-asset-fonts', '--packages=.dart_tool/package_config.json',
        '--flutter-assets-dir=' + str(assets), str(output)]
status = subprocess.run(args, env=env).returncode
if status:
    raise SystemExit(status)
for raw in sorted((project / '.dart_tool/app-store-export').glob('*.png')):
    parts = raw.stem.split('__', 1)
    directory = project / 'app_store/en-US' / parts[0]
    directory.mkdir(parents=True, exist_ok=True)
    subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '95',
                    str(raw), '--out', str(directory / (parts[1] + '.jpg'))], check=True,
                   stdout=subprocess.DEVNULL)
print('App Store JPEGs exported without alpha.')
