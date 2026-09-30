"""Verify a local reproduction ZIP or an extracted folder without executing its contents."""
import hashlib
import json
import pathlib
import sys
import zipfile

target = pathlib.Path(sys.argv[1]).resolve()
if target.is_file():
    with zipfile.ZipFile(target) as archive:
        if archive.testzip() is not None:
            raise SystemExit('ZIP integrity failed')
        records = json.loads(archive.read('manifest.json'))
        for record in records:
            if hashlib.sha256(archive.read(record['path'])).hexdigest() != record['sha256']:
                raise SystemExit('Hash mismatch: ' + record['path'])
elif target.is_dir():
    records = json.loads((target / 'manifest.json').read_text(encoding='utf-8'))
    for record in records:
        path = (target / record['path']).resolve()
        if not path.is_relative_to(target) or not path.is_file():
            raise SystemExit('Missing or invalid path: ' + record['path'])
        if hashlib.sha256(path.read_bytes()).hexdigest() != record['sha256']:
            raise SystemExit('Hash mismatch: ' + record['path'])
else:
    raise SystemExit('Expected a ZIP or extracted folder')
print('Verified', len(records), 'SHA-256 records. This checks files, not physical validity or cross-machine reproduction.')
