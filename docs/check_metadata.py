#!/usr/bin/env python3
"""Checks every copy-paste block in APP_STORE_METADATA.md against the "(max N)" limit in its heading."""
import re
import sys
from pathlib import Path

text = (Path(__file__).parent / "APP_STORE_METADATA.md").read_text(encoding="utf-8")
failed = False
checked = 0
for section in re.split(r"^### ", text, flags=re.M)[1:]:
    heading = section.split("\n", 1)[0]
    limit = re.search(r"\(max (\d+)", heading)
    block = re.search(r"^```\n(.*?)\n```", section, re.M | re.S)
    if not limit or not block:
        continue
    checked += 1
    block = block.group(1)
    ok = len(block) <= int(limit.group(1))
    if "Keywords" in heading and (", " in block or "\n" in block):
        ok = False
    failed |= not ok
    print(f"{'OK  ' if ok else 'FAIL'} {len(block):>4}/{limit.group(1):<4} {heading}")
if checked == 0:
    sys.exit("No limited fields found; the heading format changed.")
sys.exit(1 if failed else 0)
