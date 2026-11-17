#!/usr/bin/env python3
"""Expose a bounded log excerpt in the check API when artifact storage is unreachable."""
from pathlib import Path
import re

logs = [p for p in Path('build-logs').glob('*.log') if p.is_file()]
if logs:
    log = max(logs, key=lambda p: p.stat().st_mtime)
    lines = log.read_text(errors='replace').splitlines()
    errors = [line for line in lines if re.search(
        r'error:|fatal:|Error [0-9]|No space left|not found|Cannot fetch|failed',
        line, re.IGNORECASE)]
    excerpt = '\n'.join((errors or lines)[-20:])[-6000:]
    message = f'{log.name}\n{excerpt}'
else:
    message = 'No build log was created; inspect the failed workflow setup step.'
message = message.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
print(f'::error title=Ancora ROM build failure::{message}')
