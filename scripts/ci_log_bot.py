#!/usr/bin/env python3
"""
CI log fetcher for the drago repo.

Features:
- Grabs the latest GitHub Actions run logs for this repo (default: thagore-foundation/drago).
- Skips log lines from the LLVM install step to keep the output focused.
- Works without a token on public repos; set GITHUB_TOKEN to raise rate limits.

Usage:
  python scripts/ci_log_bot.py            # fetch latest run on default branch
  python scripts/ci_log_bot.py --run 123  # fetch specific run id
  GITHUB_TOKEN=ghp_xxx python scripts/ci_log_bot.py --jobs    # list jobs only
"""

import argparse
import io
import os
import sys
import zipfile
from typing import Iterable

import json
import urllib.request
import urllib.error


API_ROOT = "https://api.github.com"
DEFAULT_OWNER = "thagore-foundation"
DEFAULT_REPO = "drago"


def github_request(url: str) -> bytes:
    headers = {"User-Agent": "ci-log-bot"}
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:  # nosec
            return resp.read()
    except urllib.error.HTTPError as e:
        sys.stderr.write(f"GitHub API error {e.code}: {e.reason}\n")
        sys.exit(1)


def latest_run(owner: str, repo: str) -> int:
    url = f"{API_ROOT}/repos/{owner}/{repo}/actions/runs?per_page=1"
    data = json.loads(github_request(url).decode("utf-8"))
    runs = data.get("workflow_runs", [])
    if not runs:
        sys.stderr.write("No workflow runs found\n")
        sys.exit(1)
    return int(runs[0]["id"])


def list_jobs(owner: str, repo: str, run_id: int):
    url = f"{API_ROOT}/repos/{owner}/{repo}/actions/runs/{run_id}/jobs?per_page=100"
    data = json.loads(github_request(url).decode("utf-8"))
    for job in data.get("jobs", []):
        name = job.get("name", "<unknown>")
        conclusion = job.get("conclusion")
        status = job.get("status")
        print(f"{job['id']}: {name} [{status}/{conclusion}]")


def iter_log_lines(log_zip: bytes) -> Iterable[str]:
    with zipfile.ZipFile(io.BytesIO(log_zip)) as zf:
        for name in zf.namelist():
            with zf.open(name) as f:
                for raw in f:
                    yield raw.decode("utf-8", errors="replace").rstrip("\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", default=DEFAULT_OWNER)
    ap.add_argument("--repo", default=DEFAULT_REPO)
    ap.add_argument("--run", type=int, help="workflow run id (default: latest)")
    ap.add_argument("--jobs", action="store_true", help="list jobs and exit")
    ap.add_argument("--skip-substr", default="Install LLVM", help="substring to skip from logs")
    args = ap.parse_args()

    run_id = args.run or latest_run(args.owner, args.repo)
    if args.jobs:
        list_jobs(args.owner, args.repo, run_id)
        return

    url = f"{API_ROOT}/repos/{args.owner}/{args.repo}/actions/runs/{run_id}/logs"
    log_zip = github_request(url)

    skipped = 0
    shown = 0
    for line in iter_log_lines(log_zip):
        if args.skip_substr and args.skip_substr in line:
            skipped += 1
            continue
        print(line)
        shown += 1

    sys.stderr.write(f"\n[ci-log-bot] run={run_id} lines shown={shown} skipped={skipped}\n")


if __name__ == "__main__":
    main()
