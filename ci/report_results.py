"""Publish JUnit counts and failed test names without a write-scoped token."""

from html import escape
import os
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def main(path):
    source = Path(path)
    if not source.exists():
        print("::error::Test results are missing; inspect dependency or startup failures.")
        return 1
    root = ET.parse(source).getroot()
    tests = list(root.iter("testcase"))
    failed = [case for case in tests if case.find("failure") is not None
              or case.find("error") is not None]
    skipped = [case for case in tests if case.find("skipped") is not None]
    lines = [f"## {escape(source.stem)} tests", "",
             f"{len(tests)} collected; {len(failed)} failed/errored; {len(skipped)} skipped.", ""]
    for case in failed:
        lines.append(f"- **Failed:** {escape(case.get('classname', ''))}.{escape(case.get('name', ''))}")
    lines.append("\nOpen the job log for assertions; download the matching results artifact for JUnit XML and available browser traces.")
    print("\n".join(lines))
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as stream:
            stream.write("\n".join(lines) + "\n")
    if not tests or len(tests) == len(skipped) or failed:
        print("::error::Tests failed, errored, or no active tests ran.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1]))
