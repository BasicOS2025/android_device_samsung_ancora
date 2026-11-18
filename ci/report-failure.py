#!/usr/bin/env python3
"""Expose a bounded log excerpt in the check API when artifact storage is unreachable."""
from pathlib import Path
import re
import sys
import json
import os
import urllib.request

log_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('build-logs')
attempts = [p for p in log_dir.glob('attempt-*.log') if p.is_file()]
logs = attempts or [p for p in log_dir.glob('*.log') if p.is_file()]
if logs:
    log = max(logs, key=lambda p: p.stat().st_mtime)
    lines = log.read_text(errors='replace').splitlines()
    errors = [line for line in lines if re.search(
        r'error:|fatal:|Error [0-9]|No space left|not found|Cannot fetch|failed|'
        r'neverallow|syntax error|policy error|checkpolicy|section mismatch',
        line, re.IGNORECASE)]
    # APK/ZIP tools often print no "error:" prefix. Keep the command's output
    # beside each Ninja failure instead of losing the actual cause to filtering.
    failures = [i for i, line in enumerate(lines) if line.startswith('FAILED:')]
    if failures:
        selected = set(range(max(0, len(lines) - 25), len(lines)))
        for i in failures[-4:]:
            selected.update(range(i, min(i + 16, len(lines))))
        details = [lines[i][:1500] for i in sorted(selected)]
    else:
        details = (errors or lines)[-60:]
    excerpt = '\n'.join(details)[-12000:]
    progress = [re.search(r'\[\s*\d+%\s+\d+/\d+\]', line) for line in lines]
    progress = [match.group(0) for match in progress if match]
    last_progress = progress[-1] if progress else 'unavailable'
    message = f'{log.name}\nLast reported attempt progress: {last_progress}\n{excerpt}'
else:
    message = 'No build log was created; inspect the failed workflow setup step.'
annotation = message.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
print(f'::error title=Ancora ROM build failure::{annotation}')

# Native step annotations can be delayed until a long-running job finishes.
# Publish a bounded check result so the current error is readable during retries.
token = os.environ.get('GH_TOKEN')
repository = os.environ.get('GITHUB_REPOSITORY', '')
revision_file = log_dir / 'device-revision.txt'
revision = revision_file.read_text().strip() if revision_file.is_file() else os.environ.get('GITHUB_SHA', '')
if token and re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository) and re.fullmatch(r'[a-f0-9]{40}', revision):
    payload = {
        'name': 'Ancora ROM build diagnostic',
        'head_sha': revision,
        'status': 'completed',
        'conclusion': 'failure',
        'details_url': f'https://github.com/{repository}/actions/runs/{os.environ.get("GITHUB_RUN_ID", "")}',
        'output': {'title': 'ROM compilation failed', 'summary': message},
    }
    request = urllib.request.Request(
        f'https://api.github.com/repos/{repository}/check-runs',
        data=json.dumps(payload).encode(),
        headers={'Authorization': f'Bearer {token}', 'Accept': 'application/vnd.github+json', 'Content-Type': 'application/json'},
        method='POST',
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            print('Published live build diagnostic check:', response.status)
    except Exception as error:
        print('Could not publish live diagnostic check:', type(error).__name__)
