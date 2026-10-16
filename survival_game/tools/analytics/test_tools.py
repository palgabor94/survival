"""Offline tests: setup is repeatable and reports cannot double-count retries."""
import importlib.util
import io
import json
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch


def load(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(name + '.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


setup = load('setup_firebase')
analyzer = load('analyze')


class ToolsTest(unittest.TestCase):
    def test_setup_creates_then_reuses_exact_identifiers(self):
        projects, apps, calls = [], [], []
        def fake_cli(*args):
            calls.append(args)
            command = args[0]
            if command == 'projects:list':
                return {'projects': projects}
            if command == 'projects:create':
                projects.append({'projectId': setup.PROJECT})
                return {}
            if command == 'apps:list':
                return apps
            if command == 'apps:create':
                platform = args[1]
                app = {'appId': platform, ('bundleId' if platform == 'ios' else 'packageName'): args[4]}
                apps.append(app)
                return app
            if command == 'apps:sdkconfig':
                if args[1] == 'ios':
                    contents = plistlib.dumps(dict(API_KEY='public-ios', GOOGLE_APP_ID='ios-app',
                        GCM_SENDER_ID='123', PROJECT_ID=setup.PROJECT, BUNDLE_ID=setup.IOS_BUNDLE)).decode()
                else:
                    contents = json.dumps({'project_info': {'project_number': '123', 'project_id': setup.PROJECT},
                        'client': [{'client_info': {'mobilesdk_app_id': 'android-app',
                            'android_client_info': {'package_name': setup.ANDROID_PACKAGE}},
                            'api_key': [{'current_key': 'public-android'}]}]})
                return {'fileContents': contents}
            self.fail(command)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'assets/config').mkdir(parents=True)
            with patch.object(setup, 'ROOT', root), patch.object(setup, 'cli', fake_cli), patch('sys.stdout', new_callable=io.StringIO):
                setup.setup(setup.PROJECT)
                setup.setup(setup.PROJECT)
            config = json.loads((root / 'assets/config/firebase.json').read_text())
            self.assertEqual(config['ios']['iosBundleId'], 'com.palgabor.lostcanopy')
            self.assertTrue(config['configured'])
            self.assertIn('google_app_id', (root / 'android/app/src/main/res/values/firebase_options.xml').read_text())
        self.assertEqual(sum(c[0] == 'projects:create' for c in calls), 1)
        self.assertEqual(sum(c[0] == 'apps:create' for c in calls), 2)

    def test_dedupe_dwell_and_incomplete_are_reported_separately(self):
        def row(i, name, **values):
            return dict(name='lc_' + name, at=f'2026-10-16T00:00:{i:02}Z', player_id='p',
                parameters=dict(event_id=str(i), session_id='s', run_id='r', day=4, **values))
        rows = [row(1, 'run_loaded'), row(2, 'screen_time', screen='camp', duration_ms=5000),
            row(3, 'run_ended', outcome='lost', fatal_location='riverbank')]
        report = analyzer.analyze(rows + [rows[-1]])
        self.assertEqual(report['events'], 3)
        self.assertEqual(report['outcomes'], {'lost': 1})
        self.assertEqual(report['screen_seconds'], {'camp': 5})
        self.assertEqual(report['deaths_by_location'], {'riverbank': 1})
        self.assertEqual(analyzer.analyze(rows[:-1])['unfinished_runs'], 1)
        self.assertIn('do not prove boredom', analyzer.markdown(report))


if __name__ == '__main__':
    unittest.main()
