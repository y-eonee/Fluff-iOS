#!/usr/bin/env python3
"""Capture isolated production-view fixtures using simctl (never a physical device).

Requires a DEBUG Simulator build with DesignPreview. Source screenshots are QA
references only and are never copied into app resources by this script.
"""
import argparse
import json
from pathlib import Path
import subprocess
import time
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True, help='Booted Simulator UUID')
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--start', type=int, default=0)
    parser.add_argument('--count', type=int, default=52)
    parser.add_argument('--wait', type=float, default=6, help='Minimum settling time for native UI')
    parser.add_argument('--manifest', type=Path, default=Path(__file__).with_name('design-frame-qa.json'))
    args = parser.parse_args()
    devices = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', '--json']))
    device = next((d for group in devices['devices'].values() for d in group if d['udid'] == args.device), None)
    if device is None or device['state'] != 'Booted':
        parser.error('A booted Simulator UUID is required.')
    manifest = json.loads(args.manifest.read_text())
    targets = [r for r in manifest['frames'] if 'route' in r][args.start:args.start + args.count]
    args.output.mkdir(parents=True, exist_ok=True)
    container = Path(subprocess.check_output(['xcrun', 'simctl', 'get_app_container', args.device,
                                              'com.nayeon.Malrang', 'data'], text=True).strip())
    ready_file = container / 'Documents/design-frame-ready.json'
    records = []
    for row in targets:
        path = args.output / row['renderPath']
        path.parent.mkdir(parents=True, exist_ok=True)
        nonce = str(uuid.uuid4())
        started = time.monotonic()
        subprocess.run(['xcrun', 'simctl', 'launch', '--terminate-running-process', args.device,
                        'com.nayeon.Malrang', *row['arguments'], '--qa-capture-id=' + nonce], check=True)
        ready = False
        while not ready and time.monotonic() - started < 120:
            try:
                signal = json.loads(ready_file.read_text())
                ready = signal.get('captureID') == nonce and signal.get('startupFinished') == 'true'
            except (FileNotFoundError, json.JSONDecodeError):
                pass
            if not ready:
                time.sleep(0.5)
        settling = max(args.wait, row.get('minimumWaitSeconds', 0))
        time.sleep(max(2, settling - (time.monotonic() - started)))
        subprocess.run(['xcrun', 'simctl', 'io', args.device, 'screenshot', str(path)], check=True)
        record = {'id': row['id'], 'route': row['route'], 'path': str(path),
                  'capturedAt': time.strftime('%Y-%m-%dT%H:%M:%S%z'),
                  'elapsedSeconds': round(time.monotonic() - started, 2),
                  'sceneReady': ready, 'readinessRequired': True}
        records.append(record)
        print(json.dumps(record), flush=True)
        (args.output / f'capture-{args.start}.json').write_text(json.dumps(records, indent=2) + '\n')


if __name__ == '__main__':
    main()
