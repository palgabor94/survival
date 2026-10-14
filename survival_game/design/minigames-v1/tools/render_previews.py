#!/usr/bin/env python3
"""Render design-only Flutter previews without gameplay tests or a VM service."""
import os
from pathlib import Path
import shutil
import subprocess

project = Path(__file__).resolve().parents[3]
os.chdir(project)
sdk = Path(os.environ.get('LOST_CANOPY_CAPTURE_SDK', '/private/tmp/lost-canopy-flutter-sdk'))
engines = sdk / 'bin/cache/artifacts/engine'
engine = engines / 'darwin-x64'
if not engine.exists():
    engine = engines / 'darwin-arm64'
output = project / '.dart_tool/minigame_design_previews.dill'
logfile = project / 'design/minigames-v1/compile.log'
args = [str(sdk / 'bin/cache/dart-sdk/bin/dartaotruntime'),
        str(engine / 'frontend_server_aot.dart.snapshot'), '--sdk-root',
        str(engines / 'common/flutter_patched_sdk') + '/', '--target=flutter',
        '--enable-asserts', '--no-print-incremental-dependencies',
        '--packages=.dart_tool/package_config.json', '--output-dill', str(output),
        'design/minigames-v1/tools/render_previews.dart']
with logfile.open('w') as log:
    status = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT).returncode
if status or 'Error:' in logfile.read_text():
    print(logfile.read_text())
    raise SystemExit(status or 1)
assets = project / 'build/unit_test_assets'
assets.mkdir(parents=True, exist_ok=True)
shutil.copytree(project / 'assets', assets / 'assets', dirs_exist_ok=True)
env = os.environ.copy()
env['FLUTTER_ROOT'] = str(sdk)
env['FLUTTER_TEST'] = 'true'
raise SystemExit(subprocess.run([
    str(engine / 'flutter_tester'), '--disable-vm-service', '--enable-checked-mode',
    '--enable-software-rendering', '--skia-deterministic-rendering',
    '--use-test-fonts', '--disable-asset-fonts', '--packages=.dart_tool/package_config.json',
    '--flutter-assets-dir=' + str(assets), str(output)], env=env).returncode)
