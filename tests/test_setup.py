import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec=importlib.util.spec_from_file_location('yogurt_setup',Path(__file__).resolve().parents[1]/'setup.py')
s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)

class SetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);self.profile=self.root/'profile';self.profile.mkdir()
        self.settings=self.profile/'settings.json'
    def test_enable_preserves_preferences_and_private_backup(self):
        original=b'{"showInMenuBar":false,"myName":"Test","calendarLinks":[{"url":"private"}]}'
        self.settings.write_bytes(original)
        with patch.object(s,'running',return_value=False):
            self.assertTrue(s.enable_tray(self.profile))
        result=json.loads(self.settings.read_text());result['showInMenuBar']=False
        self.assertEqual(result,json.loads(original))
        backup=next(self.profile.glob('settings.json.before-*'))
        self.assertEqual(backup.read_bytes(),original);self.assertEqual(backup.stat().st_mode & 0o777,0o600)
    def test_running_app_cannot_lose_preferences(self):
        raw=b'{"showInMenuBar":false}';self.settings.write_bytes(raw)
        with patch.object(s,'running',return_value=True),self.assertRaises(ValueError):
            s.enable_tray(self.profile)
        self.assertEqual(self.settings.read_bytes(),raw)
        self.assertEqual(list(self.profile.glob('settings.json.before-*')),[])
    def test_default_and_enabled_preferences_untouched(self):
        self.assertFalse(s.enable_tray(self.profile));self.assertFalse(self.settings.exists())
        raw=b'{"showInMenuBar":true,"welcomed":true}';self.settings.write_bytes(raw)
        self.assertFalse(s.enable_tray(self.profile));self.assertEqual(self.settings.read_bytes(),raw)
    def test_invalid_and_linked_settings_fail_closed(self):
        self.settings.write_text('broken')
        with self.assertRaises(ValueError):s.enable_tray(self.profile)
        self.assertEqual(self.settings.read_text(),'broken')
        self.settings.unlink();target=self.root/'other';target.write_text('{}');self.settings.symlink_to(target)
        with self.assertRaises(ValueError):s.enable_tray(self.profile)
        self.assertEqual(target.read_text(),'{}')
    def test_concurrent_changes_not_overwritten(self):
        self.settings.write_text('{"showInMenuBar":false}')
        calls=[]
        def second_check():
            calls.append(1)
            if len(calls)==2:self.settings.write_text('{"showInMenuBar":false,"new":true}')
            return False
        with patch.object(s,'running',side_effect=second_check),self.assertRaises(ValueError):
            s.enable_tray(self.profile)
        self.assertIn('new',self.settings.read_text())
    def test_modified_download_rejected(self):
        response=io.BytesIO(b'not the official app');response.url=s.URL
        with patch.object(s.urllib.request,'urlopen',return_value=response),self.assertRaises(ValueError):
            s.download(self.root/'app')
    def test_clean_install_creates_launcher_and_keeps_app_executable(self):
        with patch.dict(os.environ,{'XDG_DATA_HOME':str(self.root)}),patch.object(s,'download',side_effect=lambda p:(p.write_bytes(b'app'),p.chmod(0o755))):
            command=s.install_app()
            self.assertEqual(command,['gtk-launch','yogurt'])
            desktop=(self.root/'applications/yogurt.desktop').read_text()
            self.assertIn('--appimage-extract-and-run',desktop)
            app=self.root/'yogurt-bar'/f'Yogurt-{s.VERSION}.AppImage'
            self.assertTrue(app.stat().st_mode & 0o111)
            self.assertTrue((app.parent/'yogurt.png').is_file())
    def test_existing_desktop_is_not_replaced(self):
        with patch.dict(os.environ,{'XDG_DATA_HOME':str(self.root)}),patch.object(s,'download',side_effect=lambda p:p.write_bytes(b'app')):
            desktop=self.root/'applications/yogurt.desktop';desktop.parent.mkdir();desktop.write_text('existing')
            with self.assertRaises(FileExistsError):s.install_app()
            self.assertEqual(desktop.read_text(),'existing')
    def test_launcher_detection_and_exec_quoting(self):
        with patch.object(s,'desktop_exists',return_value=True),patch.object(s.shutil,'which',return_value='/usr/bin/gtk-launch'):
            self.assertTrue(s.installed(['gtk-launch','yogurt']))
        with self.assertRaises(ValueError):s.installed('sh -c bad')
        self.assertEqual(s.desktop_quote('/a b/100%/$file'),r'"/a b/100%%/\$file"')

if __name__=='__main__':unittest.main()
