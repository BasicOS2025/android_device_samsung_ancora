#!/usr/bin/env python3
"""Collect actual OTA outputs; never fabricate a ROM ZIP from source files."""
import argparse
import hashlib
from pathlib import Path
import shutil
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('product_out', type=Path)
parser.add_argument('destination', type=Path)
args = parser.parse_args()
outputs = sorted(args.product_out.glob('lineage-15.1-*-ancora.zip'))
if not outputs:
    raise SystemExit('No LineageOS 15.1 Ancora OTA ZIP was produced.')
args.destination.mkdir(parents=True, exist_ok=True)
hashes = []
for output in outputs:
    with zipfile.ZipFile(output) as archive:
        names = set(archive.namelist())
        if 'boot.img' not in names or 'META-INF/com/android/metadata' not in names:
            raise SystemExit(f'{output.name}: missing OTA boot image or metadata')
        with archive.open('boot.img') as boot:
            if boot.read(8) != b'ANDROID!':
                raise SystemExit(f'{output.name}: invalid Android boot image header')
        if not names.intersection({'system.new.dat', 'system.new.dat.br', 'system.img'}):
            raise SystemExit(f'{output.name}: missing system payload')
        metadata = archive.read('META-INF/com/android/metadata').decode()
        if not any(line.startswith('pre-device=') and
                   'ancora' in line.split('=', 1)[1].split(',')
                   for line in metadata.splitlines()):
            raise SystemExit(f'{output.name}: unexpected target device')
        if archive.testzip() is not None:
            raise SystemExit(f'{output.name}: corrupted archive')
    digest = hashlib.sha256()
    with output.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    shutil.copy2(output, args.destination / output.name)
    hashes.append(f'{digest.hexdigest()}  {output.name}')
(args.destination / 'SHA256SUMS').write_text('\n'.join(hashes) + '\n')
print(f'Collected {len(outputs)} OTA ZIP(s). Boot/hardware testing remains outstanding.')
