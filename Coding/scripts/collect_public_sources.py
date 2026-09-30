"""Download public engineering references into a NEW directory; never overwrite."""
import concurrent.futures
import datetime
import hashlib
import html
import json
import pathlib
import re
import subprocess
import tempfile
import urllib.request

SOURCES = {
    'nasa_propulsion': 'https://www.nasa.gov/smallsat-institute/sst-soa/in-space_propulsion/',
    'nasa_deorbit': 'https://www.nasa.gov/smallsat-institute/sst-soa/deorbit-systems/',
    'nasa_power': 'https://www.nasa.gov/smallsat-institute/sst-soa/power/',
    'vallado_catalog': 'https://celestrak.org/software/vallado-sw.php',
    'vallado_data': 'https://raw.githubusercontent.com/CelesTrak/fundamentals-of-astrodynamics/main/software/misc/pascal/ATMOSEXP.DAT',
    'busek_bht200': 'https://www.busek.com/bht200',
}

def collect(folder, name, url):
    record = {'id': name, 'url': url, 'accessedUtc': datetime.datetime.now(datetime.timezone.utc).isoformat()}
    try:
        response = subprocess.run(['curl.exe','--fail','--location','--max-time','25',
            '--silent','--show-error',url],capture_output=True,timeout=30,check=True)
        data = response.stdout
        suffix = '.dat' if url.endswith('.DAT') else '.html'
        path = folder / (name + suffix)
        with path.open('xb') as handle:
            handle.write(data)
        record.update(status='downloaded_not_certified', file=path.name,
                      sha256=hashlib.sha256(data).hexdigest())
        if suffix == '.html':
            text = data.decode('utf-8', errors='replace')
            text = re.sub(r'<(script|style)\b[^>]*>.*?</\1>', '', text, flags=re.S|re.I)
            text = html.unescape(re.sub('<[^>]+>', ' ', text))
            with (folder / (name + '.txt')).open('x', encoding='utf-8') as handle:
                handle.write(re.sub(r'\s+', ' ', text))
    except Exception as exc:
        record.update(status='unavailable', error=str(exc))
    return record

if __name__ == '__main__':
    root = pathlib.Path(__file__).resolve().parents[1]
    folder = root / 'data' / 'raw' / ('public_' + datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
    folder.mkdir(parents=True, exist_ok=False)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(lambda item: collect(folder, *item), SOURCES.items()))
    with (folder / 'manifest.json').open('x', encoding='utf-8') as handle:
        json.dump(results, handle, ensure_ascii=False, indent=2)
    print(folder)
    for item in results:
        print(item['id'], item['status'], item.get('error', ''))
