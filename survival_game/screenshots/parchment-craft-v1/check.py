#!/usr/bin/env python3
"""Render the actual Flutter UI without a networked test-runner service.

Uses an existing Flutter SDK; no packages are installed and no tests are run.
The Dart exporter drives widgets only to export the requested screenshot gallery.
"""
import os
from pathlib import Path
import shutil
import subprocess
import sys

project = Path(__file__).resolve().parents[2]
os.chdir(project)
sdk = Path(os.environ.get('LOST_CANOPY_CAPTURE_SDK', '/private/tmp/lost-canopy-flutter-sdk'))
if not sdk.exists():
    raise SystemExit('Set LOST_CANOPY_CAPTURE_SDK to an existing Flutter SDK.')
engines = sdk / 'bin/cache/artifacts/engine'
engine = engines / 'darwin-x64'
if not engine.exists():
    engine = engines / 'darwin-arm64'
dart = sdk / 'bin/cache/dart-sdk/bin/dartaotruntime'
compiler = engine / 'frontend_server_aot.dart.snapshot'
output = project / '.dart_tool/parchment_regression_v1.dill'
compile_log = project / '.dart_tool/card-confirmation-concept-v1-compile.log'
args = [str(dart), str(compiler), '--sdk-root', str(engines / 'common/flutter_patched_sdk') + '/',
        '--target=flutter', '--enable-asserts', '--no-print-incremental-dependencies',
        '--packages=.dart_tool/package_config.json', '--output-dill', str(output),
        'screenshots/tools/run_native_tests.dart']
with compile_log.open('w') as log:
    status = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT).returncode
if status or not output.exists() or 'Error:' in compile_log.read_text():
    print(compile_log.read_text())
    raise SystemExit(status or 1)
print('Screenshot exporter compiled.', flush=True)
assets = project / 'build/unit_test_assets'
assets.mkdir(parents=True, exist_ok=True)
shutil.copytree(project / 'assets', assets / 'assets', dirs_exist_ok=True)
env = os.environ.copy()
env['FLUTTER_ROOT'] = str(sdk)
env['FLUTTER_TEST'] = 'true'
args = [str(engine / 'flutter_tester'), '--disable-vm-service', '--enable-checked-mode',
        '--enable-software-rendering', '--skia-deterministic-rendering',
        '--use-test-fonts', '--disable-asset-fonts', '--packages=.dart_tool/package_config.json',
        '--flutter-assets-dir=' + str(assets), str(output)]
raise SystemExit(subprocess.run(args, env=env).returncode)
