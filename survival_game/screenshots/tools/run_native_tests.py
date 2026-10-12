#!/usr/bin/env python3
"""Run the repository's actual test suites without a WebSocket test launcher."""
import os
from pathlib import Path
import shutil
import subprocess

project = Path(__file__).resolve().parents[2]
os.chdir(project)
sdk = Path(os.environ.get('LOST_CANOPY_CAPTURE_SDK', '/private/tmp/lost-canopy-flutter-sdk'))
engines = sdk / 'bin/cache/artifacts/engine'
engine = engines / 'darwin-x64'
if not engine.exists():
    engine = engines / 'darwin-arm64'
output = project / '.dart_tool/native_tests.dill'
compile_log = project / '.dart_tool/native-tests-compile.log'
args = [str(sdk / 'bin/cache/dart-sdk/bin/dartaotruntime'),
        str(engine / 'frontend_server_aot.dart.snapshot'),
        '--sdk-root', str(engines / 'common/flutter_patched_sdk') + '/',
        '--target=flutter', '--enable-asserts', '--no-print-incremental-dependencies',
        '--packages=.dart_tool/package_config.json', '--output-dill', str(output),
        'screenshots/tools/run_native_tests.dart']
with compile_log.open('w') as log:
    status = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT).returncode
if status or not output.exists() or 'Error:' in compile_log.read_text():
    print(compile_log.read_text())
    raise SystemExit(status or 1)
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
