"""Run compiler and lint independently, retain diagnostics, and preserve failures."""

import os
from pathlib import Path
import subprocess


def main():
    output = Path("test-results/compiler")
    output.mkdir(parents=True, exist_ok=True)
    sources = ["main.jac", "frontend.cl.jac", "components", "services", "lib"]
    commands = {
        "compiler": ["jac", "check", *sources],
        "lint": ["jac", "lint", *sources],
    }
    failed = False
    summary = []
    for label, command in commands.items():
        result = subprocess.run(command, text=True, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, timeout=300)
        (output / f"{label}.log").write_text(result.stdout)
        print(result.stdout, end="")
        summary.append(f"- {label}: {'failed' if result.returncode else 'passed'}")
        if result.returncode:
            failed = True
            print(f"::error title=Jac {label} failed::See {label}.log in compiler-diagnostics.")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as stream:
            stream.write("## Jac analysis\n\n" + "\n".join(summary) + "\n")
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
