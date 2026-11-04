"""Isolated checks for published desktop configuration, not the live session."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DesktopConfigTests(unittest.TestCase):
    def test_launch_uses_selected_config_directory_without_starting_real_apps(self):
        with tempfile.TemporaryDirectory(prefix='df-') as directory:
            root = Path(directory)
            home, config, binary = root / 'home with spaces', root / 'xdg config', root / 'bin'
            home.mkdir()
            config.mkdir()
            binary.mkdir()
            for name in ('pkill', 'sleep', 'hyprpaper', 'waybar', 'mako', 'hypridle'):
                stub = binary / name
                stub.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$LOG_DIR/' + name + '.args"\n')
                stub.chmod(0o755)
            bash = shutil.which('bash')
            assert bash is not None
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(config),
                       PATH=str(binary), LOG_DIR=str(root))
            result = subprocess.run([bash, str(ROOT / '.config/hypr/launch.sh')], env=env,
                                    capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            for name, relative in [('hyprpaper', 'hypr/hyprpaper.conf'),
                                   ('waybar', 'waybar/config.jsonc'),
                                   ('mako', 'mako/config'), ('hypridle', 'hypr/hypridle.conf')]:
                with self.subTest(program=name):
                    self.assertEqual((root / (name + '.args')).read_text().splitlines()[:2],
                                     ['-c', str(config / relative)])

    def test_zsh_highlight_colors_have_one_hex_prefix(self):
        with tempfile.TemporaryDirectory(prefix='df-') as directory:
            zsh = shutil.which('zsh')
            assert zsh is not None
            env = dict(os.environ, HOME=directory, ZDOTDIR=directory, TERM='dumb')
            command = 'source "$1"; print -rl -- "$ZSH_HIGHLIGHT_STYLES[path]" "$ZSH_HIGHLIGHT_STYLES[unknown-token]"'
            result = subprocess.run([zsh, '-dfc', command, 'zsh', str(ROOT / '.zshrc')],
                                    env=env, capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.splitlines(), ['fg=#999050', 'fg=#b50f04'])

    def test_zsh_starts_cleanly_without_optional_programs(self):
        with tempfile.TemporaryDirectory(prefix='df-') as directory:
            home = Path(directory) / 'home with spaces'
            empty_bin = home / 'empty-bin'
            empty_bin.mkdir(parents=True)
            # Keep core utilities available, but no optional desktop programs.
            mv = shutil.which('mv')
            zsh = shutil.which('zsh')
            assert mv is not None and zsh is not None
            (empty_bin / 'mv').symlink_to(mv)
            env = dict(os.environ, HOME=str(home), ZDOTDIR=str(home),
                       PATH=str(empty_bin), TERM='dumb')
            command = 'source "$1"; print -r -- "$PATH"; alias cyberbill; alias writerbob'
            result = subprocess.run([zsh, '-dfc', command,
                                     'zsh', str(ROOT / '.zshrc')], env=env,
                                    capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stderr, '')
            self.assertIn(str(home / '.local/bin'), result.stdout.splitlines()[0])
            self.assertIn('hermes -p cyberbill chat', result.stdout)
            self.assertIn('hermes -p writerbob chat', result.stdout)

    def test_focus_commands_use_the_selected_home_even_with_spaces(self):
        config = json.loads((ROOT / '.config/waybar/config.jsonc').read_text())
        self.assertIn('custom/focus', config['modules-center'])
        focus = config['custom/focus']
        with tempfile.TemporaryDirectory(prefix='df-') as directory:
            home = Path(directory) / 'home with spaces'
            binary = home / '.local/bin/focus-mode'
            binary.parent.mkdir(parents=True)
            # A test double verifies command expansion without changing a timer.
            binary.write_text('#!/bin/sh\nprintf "%s\\n" "$*"\n')
            binary.chmod(0o755)
            env = dict(os.environ, HOME=str(home))
            for field, arguments in [('exec', '--watch'), ('on-click', ''),
                                     ('on-click-right', 'stop')]:
                with self.subTest(field=field):
                    result = subprocess.run(['sh', '-c', focus[field]], env=env,
                                            capture_output=True, text=True, timeout=5)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout.strip(), arguments)


if __name__ == '__main__':
    unittest.main()
