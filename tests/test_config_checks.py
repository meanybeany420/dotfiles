from pathlib import Path
import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ConfigCheckTests(unittest.TestCase):
    def checker(self):
        path = ROOT / 'scripts/check_configs.py'
        self.assertTrue(path.is_file(), 'Configuration checker is not implemented')
        spec = importlib.util.spec_from_file_location('dotfiles_checks', path)
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_private_state_and_backups_are_ignored(self):
        paths = ['.ssh/id_ed25519', '.README.md.swn',
                 '.config/hypr/monitors.lua.before-fix',
                 '.config/hypr/monitor-mode',
                 '.config/hypr/system-tools-displays.json',
                 'tests/__pycache__/cached.pyc']
        for name in paths:
            with self.subTest(name=name):
                result = subprocess.run(['git', 'check-ignore', '-q', '--', name],
                                        cwd=ROOT, timeout=5)
                self.assertEqual(result.returncode, 0, name)

    def test_cli_reports_failures_with_a_nonzero_exit_code(self):
        result = subprocess.run([sys.executable, str(ROOT / 'scripts/check_configs.py')],
                                cwd=ROOT, capture_output=True, text=True, timeout=30)
        self.assertTrue(result.stdout.strip(), 'Checker CLI produced no report')
        report = json.loads(result.stdout)
        self.assertIn('checked', report)
        self.assertIn('issues', report)
        self.assertEqual(result.returncode, 1 if report['issues'] else 0)

    def test_cli_rejects_an_invalid_fixture_checkout(self):
        with tempfile.TemporaryDirectory(prefix='df-') as directory:
            root = Path(directory)
            (root / 'scripts').mkdir()
            shutil.copy2(ROOT / 'scripts/check_configs.py', root / 'scripts/check_configs.py')
            subprocess.run(['git', 'init', '-q'], cwd=root, check=True,
                           capture_output=True, timeout=5)
            (root / 'invalid.json').write_text('{broken:')
            result = subprocess.run([sys.executable, str(root / 'scripts/check_configs.py')],
                                    cwd=root, capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 1)
            self.assertIn('invalid.json', '\n'.join(json.loads(result.stdout)['issues']))

    def test_invalid_configuration_syntax_is_rejected(self):
        cases = [('bad.lua', 'function('), ('bad.lua.example', 'function('),
                 ('bad.jsonc', "{'not-json':1}"),
                 ('bad.toml', '[incomplete'), ('bad.sh', 'if ; then'),
                 ('bad.zsh', 'if ; then')]
        with tempfile.TemporaryDirectory(prefix='df-') as directory:
            root = Path(directory)
            for name, source in cases:
                with self.subTest(name=name):
                    (root / name).write_text(source)
                    report = self.checker().check_configs(root, [name])
                    self.assertTrue(report['issues'])
                    self.assertIn(name, '\n'.join(report['issues']))

    def test_documented_placeholder_paths_are_not_mistaken_for_private_paths(self):
        text = '# set by /some/not/home/directory/file or /home/username/file'
        self.assertEqual(self.checker().privacy_findings('.p10k.zsh', text), [])
        actual = self.checker().privacy_findings('.config/app/config', '/home/someone/private')
        self.assertTrue(actual)

    def test_credentials_are_reported_without_echoing_the_value(self):
        secret = 'ghp_' + 'x' * 40
        findings = self.checker().privacy_findings('.config/app/config',
                                                  'export API_TOKEN="' + secret + '"')
        self.assertTrue(findings)
        self.assertNotIn(secret, '\n'.join(findings))

    def test_jsonc_preserves_urls_and_supports_comments_and_trailing_commas(self):
        source = '{"url":"https://example.invalid/a//b",/* note */"values":[1,2,],}'
        self.assertEqual(self.checker().load_jsonc(source),
                         {'url': 'https://example.invalid/a//b', 'values': [1, 2]})


if __name__ == '__main__':
    unittest.main()
