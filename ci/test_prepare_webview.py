import hashlib
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from prepare_webview import prepare


class PrepareWebViewTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.apk = self.root / 'external/chromium-webview/prebuilt/arm/webview.apk'
        self.apk.parent.mkdir(parents=True)
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, 'w') as archive:
            archive.writestr('AndroidManifest.xml', b'fixture manifest')
        self.payload = stream.getvalue()
        self.pointer = ('version https://git-lfs.github.com/spec/v1\n'
                        'oid sha256:' + hashlib.sha256(self.payload).hexdigest() +
                        '\nsize ' + str(len(self.payload)) + '\n').encode()

    def test_valid_pinned_apk_does_not_fetch(self):
        self.apk.write_bytes(self.payload)
        with patch('prepare_webview.subprocess.check_output', return_value=self.pointer), \
                patch('prepare_webview.subprocess.run') as fetch:
            prepare(self.root)
            fetch.assert_not_called()

    def test_pointer_is_replaced_with_verified_apk(self):
        self.apk.write_bytes(self.pointer)
        with patch('prepare_webview.subprocess.check_output', return_value=self.pointer), \
                patch('prepare_webview.subprocess.run',
                      side_effect=lambda *args, **kw: self.apk.write_bytes(self.payload)) as fetch:
            prepare(self.root)
            fetch.assert_called_once()
            self.assertEqual(self.payload, self.apk.read_bytes())

    def test_corrupt_same_size_apk_is_repaired(self):
        self.apk.write_bytes(b'x' * len(self.payload))
        with patch('prepare_webview.subprocess.check_output', return_value=self.pointer), \
                patch('prepare_webview.subprocess.run',
                      side_effect=lambda *args, **kw: self.apk.write_bytes(self.payload)) as fetch:
            prepare(self.root)
            fetch.assert_called_once()

    def test_failed_fetch_stops_the_build(self):
        self.apk.write_bytes(self.pointer)
        with patch('prepare_webview.subprocess.check_output', return_value=self.pointer), \
                patch('prepare_webview.subprocess.run',
                      side_effect=subprocess.CalledProcessError(1, 'git lfs pull')):
            with self.assertRaises(subprocess.CalledProcessError):
                prepare(self.root)

    def test_unresolved_pointer_is_rejected_after_successful_fetch(self):
        self.apk.write_bytes(self.pointer)
        with patch('prepare_webview.subprocess.check_output', return_value=self.pointer), \
                patch('prepare_webview.subprocess.run'):
            with self.assertRaisesRegex(RuntimeError, 'pinned LFS object'):
                prepare(self.root)


if __name__ == '__main__':
    unittest.main()
