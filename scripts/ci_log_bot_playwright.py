#!/usr/bin/env python3
"""
Playwright-based CI log fetcher that works without GitHub tokens on public repos.

What it does:
- Opens the Actions page, grabs the latest run (or a specific run id).
- Navigates to the run page and clicks the "Download log archive" link.
- Downloads the logs ZIP using the same browser context (no API token required for public repos).
- Saves the ZIP to disk and prints the path.

Requirements:
- python -m pip install playwright
- python -m playwright install chromium

Usage:
  python scripts/ci_log_bot_playwright.py               # latest run, default repo
  python scripts/ci_log_bot_playwright.py --run 123456  # specific run id
  python scripts/ci_log_bot_playwright.py --owner thagore-foundation --repo drago
  python scripts/ci_log_bot_playwright.py --out logs.zip
"""

import argparse
import asyncio
import os
import sys
from urllib.parse import urljoin

try:
    from playwright.async_api import async_playwright
except ImportError:
    sys.stderr.write(
        "playwright not installed. Install with:\n"
        "  python -m pip install playwright\n"
        "  python -m playwright install chromium\n"
    )
    sys.exit(1)


DEFAULT_OWNER = "thagore-foundation"
DEFAULT_REPO = "drago"
DEFAULT_OUT = "logs.zip"


async def find_latest_run(page, actions_home: str) -> str:
    await page.goto("about:blank")
    await page.goto(actions_home)
    await page.wait_for_timeout(2000)
    link = await page.query_selector("a[href*='/actions/runs/']")
    if not link:
        raise RuntimeError("Cannot find any run link on Actions page")
    href = await link.get_attribute("href")
    if not href:
        raise RuntimeError("Run link has no href")
    # href example: /thagore-foundation/drago/actions/runs/1234567890
    run_id = href.rstrip("/").split("/")[-1]
    return run_id


async def download_logs(owner: str, repo: str, run_id: str, out_path: str):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        actions_home = f"https://github.com/{owner}/{repo}/actions"
        page = await context.new_page()

        if not run_id:
            run_id = await find_latest_run(page, actions_home)
        run_url = f"https://github.com/{owner}/{repo}/actions/runs/{run_id}"
        await page.goto(run_url)
        await page.wait_for_timeout(2000)

        link = await page.query_selector("a[href*='/logs']")
        if not link:
            raise RuntimeError("Cannot find download logs link on run page")
        href = await link.get_attribute("href")
        if not href:
            raise RuntimeError("Download link missing href")
        if href.startswith("http"):
            log_url = href
        else:
            log_url = urljoin("https://github.com", href)

        resp = await context.request.get(log_url)
        if resp.status != 200:
            raise RuntimeError(f"Download failed: HTTP {resp.status}")
        data = await resp.body()
        with open(out_path, "wb") as f:
            f.write(data)
        await browser.close()
        print(f"Run {run_id} logs saved to {out_path}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner", default=DEFAULT_OWNER)
    ap.add_argument("--repo", default=DEFAULT_REPO)
    ap.add_argument("--run", help="run id (default: latest on Actions page)")
    ap.add_argument("--out", default=DEFAULT_OUT, help="output zip path")
    args = ap.parse_args()
    asyncio.run(download_logs(args.owner, args.repo, args.run, args.out))


if __name__ == "__main__":
    main()
