#!/usr/bin/env python3
"""Explicit, user-initiated Yogurt setup; no work runs on import or bar loading."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile
import time
import urllib.request

VERSION = '0.3.72'
URL = f'https://github.com/FrigadeHQ/yogurt/releases/download/v{VERSION}/Yogurt-linux-x86_64.AppImage'
SHA256 = '3b271e1ed84f8013fd5ddfaa93a9f02b8b87c09e621f85a84f555483fe141d0d'
MAX_DOWNLOAD = 1024 * 1024 * 1024


def data_home():
    return Path(os.environ.get('XDG_DATA_HOME') or Path.home() / '.local/share')


def desktop_exists(name):
    name = name if name.endswith('.desktop') else name + '.desktop'
    if '/' in name or '\\' in name:
        return False
    roots = [data_home()] + [Path(p) for p in os.environ.get('XDG_DATA_DIRS', '/usr/local/share:/usr/share').split(':') if p]
    return any((p / 'applications' / name).is_file() for p in roots)


def installed(command):
    if not isinstance(command, list) or not command or not all(isinstance(s, str) and '\0' not in s for s in command):
        raise ValueError('Invalid launcher command')
    if Path(command[0]).name == 'gtk-launch':
        return len(command) == 2 and desktop_exists(command[1]) and shutil.which(command[0]) is not None
    return shutil.which(command[0]) is not None


def running(proc=Path('/proc')):
    # Inspect executable identity, never meeting data or audio. Refuse settings
    # changes while Yogurt can overwrite them from its in-memory preferences.
    for p in proc.iterdir():
        if not p.name.isdigit() or int(p.name) == os.getpid():
            continue
        try:
            args = (p / 'cmdline').read_bytes().split(b'\0')
            exe = Path(os.fsdecode(args[0])).name.lower()
            if 'yogurt' in exe or (exe == 'electron' and any(b'/yogurt/' in a.lower() for a in args[1:])):
                return True
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            continue
    return False


def enable_tray(profile):
    path = profile / 'settings.json'
    if path.is_symlink():
        raise ValueError('Settings is a symbolic link; leaving it unchanged.')
    if path.exists() and path.stat().st_size > 1024 * 1024:
        raise ValueError('Settings file is unexpectedly large; leaving it unchanged.')
    raw = path.read_bytes() if path.exists() else None
    settings = json.loads(raw) if raw is not None else {}
    if not isinstance(settings, dict):
        raise ValueError('Settings must be an object; leaving it unchanged.')
    # Enabled by default upstream: do not touch preferences unless disabled.
    if settings.get('showInMenuBar') is not False:
        return False
    if running():
        raise ValueError('Quit Yogurt using its Quit action, then run setup again. No settings were changed.')
    backup = path.with_name(f'settings.json.before-yogurt-bar-{time.time_ns()}')
    backup_fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(backup_fd, 'wb') as out:
        out.write(raw)
    settings['showInMenuBar'] = True
    fd, tmp = tempfile.mkstemp(prefix='.yogurt-bar-', dir=profile)
    try:
        with os.fdopen(fd, 'w') as out:
            json.dump(settings, out, ensure_ascii=False, indent=2)
            out.write('\n')
        if running() or path.read_bytes() != raw:
            raise ValueError('Yogurt changed while setting up. Quit it and try again; settings were left unchanged.')
        os.replace(tmp, path)
    finally:
        Path(tmp).unlink(missing_ok=True)
    return True


def download(target):
    digest = hashlib.sha256()
    total = 0
    with urllib.request.urlopen(URL, timeout=60) as response, target.open('xb') as out:
        if not response.url.startswith('https://'):
            raise ValueError('Refusing an insecure download redirect')
        while chunk := response.read(1024 * 1024):
            total += len(chunk)
            if total > MAX_DOWNLOAD:
                raise ValueError('Download exceeds the size limit')
            digest.update(chunk)
            out.write(chunk)
            print(f'\rDownloading Yogurt… {total // (1024 * 1024)} MB', end='', flush=True)
    print()
    if digest.hexdigest() != SHA256:
        raise ValueError('Download verification failed. Nothing has been installed.')
    target.chmod(0o755)


def desktop_quote(value):
    # Desktop Entry Exec escaping, not shell quoting. Percent is a field code.
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"').replace('`', '\\`').replace('$', '\\$').replace('%', '%%') + '"'


def install_app():
    if platform.system() != 'Linux' or platform.machine() not in ('x86_64', 'AMD64'):
        raise ValueError('The official Yogurt Linux release currently requires an x86-64 computer.')
    dest = data_home() / 'yogurt-bar' / f'Yogurt-{VERSION}.AppImage'
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        with dest.open('rb') as existing:
            if hashlib.file_digest(existing, 'sha256').hexdigest() != SHA256:
                raise ValueError('An existing managed download has changed; leaving it untouched.')
    else:
        with tempfile.TemporaryDirectory(prefix='.download-', dir=dest.parent) as tmp:
            part = Path(tmp) / 'Yogurt.AppImage'
            download(part)
            os.replace(part, dest)
    icon = dest.parent / 'yogurt.png'
    shutil.copyfile(Path(__file__).resolve().parent / 'assets/yogurt.png', icon)
    desktop = data_home() / 'applications/yogurt.desktop'
    desktop.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive create protects an installation that appeared during download.
    with desktop.open('x') as out:
        out.write('[Desktop Entry]\nType=Application\nName=Yogurt\nComment=Private meeting notes\n'
                  f'Exec={desktop_quote(dest)} --appimage-extract-and-run\n'
                  f'Icon={icon}\nTerminal=false\nCategories=Office;\n')
    return ['gtk-launch', 'yogurt']


def confirm(prompt):
    return input(prompt + ' [y/N] ').strip().lower() in ('y', 'yes')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', type=Path, default=Path(os.environ.get('XDG_CONFIG_HOME') or Path.home() / '.config') / 'Yogurt')
    parser.add_argument('--launcher-json', default='["gtk-launch","yogurt"]')
    args = parser.parse_args()
    command = json.loads(args.launcher_json)
    print('\033[1;35m\n  Yogurt Bar · Let’s get you connected\033[0m\n')
    print('This setup can install Yogurt and enable its tray connection.\nYour recordings and other preferences stay in place.\n')
    if not installed(command):
        if command != ['gtk-launch', 'yogurt']:
            raise ValueError('Your custom launcher was not found. Correct it before continuing; setup will not replace it.')
        print(f'Official Yogurt {VERSION} for Linux · verified SHA-256 download\nSource: {URL}\nNo administrator access is needed.\n')
        if not confirm('Download and install Yogurt for your account?'):
            return
        command = install_app()
        print('✓ Yogurt installed and added to your app launcher.\n')
    else:
        print('✓ Existing Yogurt installation found. It will not be replaced.\n')
    path = args.profile / 'settings.json'
    if path.exists():
        if path.is_symlink() or path.stat().st_size > 1024 * 1024:
            raise ValueError('Settings is linked or unexpectedly large; leaving it unchanged.')
        settings = json.loads(path.read_text())
        if not isinstance(settings, dict):
            raise ValueError('Settings must be an object; leaving it unchanged.')
        if settings.get('showInMenuBar') is False:
            print('Yogurt’s tray icon is switched off. Quit Yogurt before continuing.\nSetup will back up settings and change only this preference.\n')
            if not confirm('Enable the tray icon?'):
                return
            enable_tray(args.profile)
    print('✓ Tray icon is enabled in settings.\n')
    print('Next, Yogurt will open. Complete its first-run checks and model downloads.\nYogurt Bar connects automatically when Yogurt’s tray appears.\nSetup does not start a recording or enable automatic launch at login.\n')
    if confirm('Open Yogurt now?'):
        subprocess.Popen(command, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f'\nCould not finish setup: {exc}')
    except (KeyboardInterrupt, EOFError):
        print('\nSetup cancelled.')
    finally:
        try:
            input('\nPress Enter to close setup…')
        except (KeyboardInterrupt, EOFError):
            pass
