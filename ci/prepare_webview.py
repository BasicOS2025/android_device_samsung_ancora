#!/usr/bin/env python3
"""Materialize and validate the manifest-pinned ARM WebView APK."""
from pathlib import Path
import hashlib
import re
import subprocess
import sys
import zipfile


def prepare(source_root):
    checkout = source_root / 'external/chromium-webview/prebuilt/arm'
    apk = checkout / 'webview.apk'
    pointer = subprocess.check_output(
        ['git', '-C', str(checkout), 'show', 'HEAD:webview.apk'])
    if pointer.startswith(b'version https://git-lfs.github.com/spec/v1\n'):
        oid = re.search(rb'^oid sha256:([a-f0-9]{64})$', pointer, re.M)
        size = re.search(rb'^size ([0-9]+)$', pointer, re.M)
        if not oid or not size:
            raise RuntimeError('Malformed WebView Git LFS pointer')
        expected_hash = oid.group(1).decode()
        expected_size = int(size.group(1))
        def matches():
            return (apk.is_file() and apk.stat().st_size == expected_size and
                    hashlib.sha256(apk.read_bytes()).hexdigest() == expected_hash)
        if not matches():
            subprocess.run(['git', '-C', str(checkout), 'lfs', 'pull',
                            '--include=webview.apk', '--exclude='], check=True)
        if not matches():
            raise RuntimeError('WebView APK does not match its pinned LFS object')
    with zipfile.ZipFile(apk) as archive:
        if 'AndroidManifest.xml' not in archive.namelist():
            raise RuntimeError('WebView APK has no AndroidManifest.xml')
        damaged = archive.testzip()
        if damaged:
            raise RuntimeError('Damaged WebView APK member: ' + damaged)
    print('ARM WebView APK verified:', apk.stat().st_size, 'bytes', flush=True)


if __name__ == '__main__':
    prepare(Path(sys.argv[1]))
