"""Create a new local reproducibility ZIP, with hashes and reference metrics."""
import datetime
import hashlib
import json
import pathlib
import sys
import zipfile

root = pathlib.Path(__file__).resolve().parents[2]
reference = pathlib.Path(sys.argv[1]).resolve()
current = any((reference/g).is_dir() for g in ['a1','a2','u1','u2'])
if current:
    import csv
    required = ['a1/tables/power_a1_summary.csv','a2/tables/deployment_summary.csv',
                'a1/tables/energy_audit.csv','a2/tables/deployment_audit.csv',
                'a1/tables/resolution_check.csv','a2/tables/resolution_check.csv',
                'u1/tables/uncertainty_summary.csv','u1/tables/uncertainty_audit.csv',
                'u1/tables/resolution_check.csv','u2/tables/uncertainty_summary.csv',
                'u2/tables/uncertainty_audit.csv','u2/tables/resolution_check.csv',
                'current_evidence.csv','current_context.csv']
    for name in required:
        if not (reference/name).is_file():
            raise SystemExit('Incomplete current experiment: '+name)
    for name in [n for n in required if n.endswith('audit.csv') or n.endswith('resolution_check.csv')]:
        rows=list(csv.DictReader((reference/name).open(encoding='utf-8-sig')))
        if not rows or any(row['pass'].lower() not in ['1','true'] for row in rows):
            raise SystemExit('Unpassed verification: '+name)
if not reference.is_dir() or not reference.is_relative_to(root / 'Coding' / 'results'):
    raise SystemExit('Expected reference tables under Coding/results')
if not current:
    for group in ['baselines','switch','density','sail','thrust','faults','supervised','hardware','power']:
        if not (reference/(group+'_summary.csv')).is_file():
            raise SystemExit('Incomplete legacy reference: '+group)
destination = root / 'exports'
destination.mkdir(exist_ok=True)
path = destination / ('reproduction_' + datetime.datetime.now().strftime('%Y%m%d_%H%M%S') + '.zip')
files = []
for base in ['Coding/config','Coding/src','Coding/scripts','Coding/tests','Coding/docs','Coding/data/processed']:
    files += [p for p in (root/base).rglob('*') if p.is_file() and p.suffix in ['.m','.py','.md','.csv','.json']]
files += list((root/'Coding').glob('*.m')) + [root/'Coding/README.md',root/'run_all.m',root/'run_current.m',root/'startup.m']
files += list((root/'Reference').glob('*.md'))
raw = root/'Coding/data/raw/public_20260930_130029'
files += [p for p in raw.iterdir() if p.suffix in ['.dat','.PAS','.pdf','.json','.txt','.html']]
if (root/'项目更改.md').is_file(): files.append(root/'项目更改.md')
records = []
with zipfile.ZipFile(path,'x',zipfile.ZIP_DEFLATED) as archive:
    for p in sorted(set(files)):
        data = p.read_bytes(); name = p.relative_to(root).as_posix()
        archive.writestr(name,data)
        records.append({'path':name,'sha256':hashlib.sha256(data).hexdigest()})
    reference_files = list(reference.glob('*_summary.csv'))
    if current:
        reference_files = [reference/'a1/tables/power_a1_summary.csv', reference/'a2/tables/deployment_summary.csv']
        reference_files += list((reference/'a1/tables').glob('*audit.csv')) + list((reference/'a2/tables').glob('*audit.csv'))
        reference_files += [reference/'a1/tables/resolution_check.csv',reference/'a2/tables/resolution_check.csv']
        reference_files += [reference/'u1/tables/uncertainty_summary.csv',reference/'u1/tables/uncertainty_audit.csv',reference/'u1/tables/resolution_check.csv']
        reference_files += [reference/'u2/tables/uncertainty_summary.csv',reference/'u2/tables/uncertainty_audit.csv',reference/'u2/tables/resolution_check.csv']
        reference_files += [reference/'current_evidence.csv',reference/'current_context.csv']
        if (reference/'assembly_manifest.json').is_file(): reference_files.append(reference/'assembly_manifest.json')
    for p in sorted(reference_files):
        name = 'Coding/reproduction_reference/'+(p.relative_to(reference).as_posix() if current else p.name)
        data = p.read_bytes(); archive.writestr(name,data)
        records.append({'path':name,'sha256':hashlib.sha256(data).hexdigest()})
    archive.writestr('manifest.json',json.dumps(records,indent=2,ensure_ascii=False))
print(path)
print('Files:',len(records),'Bytes:',path.stat().st_size)
