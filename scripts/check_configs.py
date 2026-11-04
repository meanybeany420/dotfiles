#!/usr/bin/env python3
"""Validate published configuration without loading the live desktop or editor."""
import json
import re
import subprocess
import tomllib
from pathlib import Path


STRING = r'"(?:\\.|[^"\\])*"'
COMMENTS = re.compile(STRING + r'|//[^\r\n]*|/\*.*?\*/', re.DOTALL)
TRAILING_COMMAS = re.compile(STRING + r'|,(?=\s*[}\]])', re.DOTALL)


def privacy_findings(name, text):
    """Return labels only: a failing check must not print a credential value."""
    patterns = {
        'private key': r'-----BEGIN (?:OPENSSH |RSA |EC |DSA |ENCRYPTED )?PRIVATE KEY-----',
        'GitHub token': r'(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,})',
        'literal credential assignment': r'(?im)^\s*(?:export\s+)?[A-Z_]*(?:API_KEY|SECRET|PASSWORD|TOKEN)[A-Z_]*\s*=\s*[\x22\x27]?[A-Za-z0-9_./+=-]{12,}',
    }
    issues = [f'{name}: possible {label}' for label, pattern in patterns.items()
              if re.search(pattern, text)]
    if name.startswith(('.config/', '.local/')) or name in ('.zshrc', '.tmux.conf', '.p10k.zsh'):
        homes = re.findall(r'(?<![\w/.-])/home/([A-Za-z0-9_.-]+)/', text)
        if any(user not in ('username', 'user', 'YOUR_USER') for user in homes):
            issues.append(f'{name}: contains a literal user-home path')
    return issues


def load_jsonc(source):
    """Accept JSON comments/trailing commas without changing string contents."""
    def remove_comment(match):
        token = match.group()
        return token if token.startswith('"') else re.sub(r'[^\r\n]', ' ', token)

    clean = COMMENTS.sub(remove_comment, source)
    clean = TRAILING_COMMAS.sub(
        lambda match: match.group() if match.group().startswith('"') else '', clean)
    return json.loads(clean)


def check_configs(root, names):
    issues = []
    checked = {'lua': 0, 'shell': 0, 'json': 0, 'toml': 0, 'text': 0}
    for name in sorted(set(names)):
        path = root / name
        if path.is_symlink():
            issues.append(f'{name}: review symlinks manually; not followed')
            continue
        try:
            text = path.read_text()
        except (OSError, UnicodeError):
            issues.append(f'{name}: cannot read as UTF-8 text')
            continue
        checked['text'] += 1
        private = privacy_findings(name, text)
        issues.extend(private)
        if private:
            continue
        command = None
        if path.suffix == '.lua' or name.endswith('.lua.example'):
            checked['lua'] += 1
            command = ['luac', '-p', str(path)]
        elif path.suffix == '.zsh' or path.name == '.zshrc':
            checked['shell'] += 1
            command = ['zsh', '-n', str(path)]
        elif path.suffix == '.sh' or text.startswith(('#!/bin/bash', '#!/usr/bin/env bash', '#!/bin/sh')):
            checked['shell'] += 1
            command = ['bash', '-n', str(path)]
        try:
            if path.suffix in ('.json', '.jsonc'):
                checked['json'] += 1
                load_jsonc(text) if path.suffix == '.jsonc' else json.loads(text)
            elif path.suffix == '.toml':
                checked['toml'] += 1
                tomllib.loads(text)
            if command:
                result = subprocess.run(command, capture_output=True, timeout=10)
                if result.returncode:
                    issues.append(f'{name}: {command[0]} syntax check failed')
        except (ValueError, OSError, subprocess.TimeoutExpired) as error:
            # Do not echo source lines or potential credentials from parser output.
            issues.append(f'{name}: validation failed ({type(error).__name__})')
    return {'checked': checked, 'issues': issues}


def main():
    root = Path(__file__).resolve().parents[1]
    try:
        files = subprocess.check_output(
            ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'],
            cwd=root).decode().split('\0')
        report = check_configs(root, [name for name in files if name])
    except (OSError, subprocess.CalledProcessError) as error:
        report = {'checked': {}, 'issues': [f'Cannot enumerate checkout ({type(error).__name__})']}
    print(json.dumps(report, indent=2))
    return 1 if report['issues'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
