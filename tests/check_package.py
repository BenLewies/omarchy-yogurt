from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
m=json.loads((root/'manifest.json').read_text())
assert m['id']=='bjl.yogurt' and m['schemaVersion']==1
for entry in m['entryPoints'].values():assert (root/entry).is_file()
for name in ['README.md','LICENSE','THIRD_PARTY_NOTICES.md','Widget.qml','YogurtPanel.qml','Model.js','NativeLabels.js','status.py','i18n/en.json','assets/yogurt.png','preview.png']:
    assert (root/name).is_file(),name
json.loads((root/'i18n/en.json').read_text())
for p in root.glob('*.qml'):
    text=p.read_text()
    assert 'Text.AutoText' not in text
assert 'textFormat:Text.PlainText' in (root/'YogurtPanel.qml').read_text()
print('Package files and entry points verified.')
