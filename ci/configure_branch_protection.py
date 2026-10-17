"""Add the Required CI gate without replacing existing protection settings.

Requires an authenticated `gh` session with repository administration permission.
Read-only by default. Pass --apply to make the requested repository change.
This script is deliberately never run by the untrusted-PR workflow.
"""

import argparse
import json
import subprocess

GITHUB_ACTIONS_APP_ID = 15368
CONTEXT = "Required CI"


def protection_payload(current, required):
    """Translate GitHub's read representation into its whole-protection PUT schema."""
    result = {"required_status_checks": required, "enforce_admins": True,
              "required_pull_request_reviews": None, "restrictions": None}
    if not current:
        return result
    for key in ("required_linear_history", "allow_force_pushes", "allow_deletions",
                "block_creations", "required_conversation_resolution", "lock_branch",
                "allow_fork_syncing"):
        if key in current:
            result[key] = current[key]["enabled"]
    def actors(value):
        return {"users": [u["login"] for u in value.get("users", [])],
                "teams": [t["slug"] for t in value.get("teams", [])],
                "apps": [a["slug"] for a in value.get("apps", [])]}
    if current.get("restrictions") is not None:
        result["restrictions"] = actors(current["restrictions"])
    if current.get("required_pull_request_reviews") is not None:
        existing = current["required_pull_request_reviews"]
        reviews = {key: existing[key] for key in (
            "dismiss_stale_reviews", "require_code_owner_reviews",
            "required_approving_review_count", "require_last_push_approval"
        ) if key in existing}
        for key in ("dismissal_restrictions", "bypass_pull_request_allowances"):
            if key in existing:
                reviews[key] = actors(existing[key])
        result["required_pull_request_reviews"] = reviews
    return result


def api(path, method="GET", payload=None, allow_missing=False):
    command = ["gh", "api", "--method", method, path]
    if payload is not None:
        command += ["--input", "-"]
    result = subprocess.run(command, input=json.dumps(payload) if payload is not None else None,
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        if allow_missing and "HTTP 404" in result.stderr:
            return None
        raise RuntimeError(result.stderr.strip())
    return json.loads(result.stdout) if result.stdout.strip() else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default="kavindusubasingha313/indoor-navigation-app")
    parser.add_argument("--branch", default="main")
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    repository = api(f"repos/{args.repo}")
    if not repository.get("permissions", {}).get("admin"):
        raise RuntimeError("Repository administration permission is required; no settings changed.")
    prefix = f"repos/{args.repo}/branches/{args.branch}/protection"
    # Confirm the branch exists before interpreting protection's 404.
    api(f"repos/{args.repo}/branches/{args.branch}")
    current = api(prefix, allow_missing=True)
    status = (current or {}).get("required_status_checks") or {}
    checks = [{"context": check["context"], "app_id": check.get("app_id", -1)}
              for check in status.get("checks", [])]
    represented = {check["context"] for check in checks}
    checks.extend({"context": context, "app_id": -1}
                  for context in status.get("contexts", []) if context not in represented)
    # Preserve unrelated required checks, while binding our gate to GitHub Actions.
    checks = [check for check in checks if check["context"] != CONTEXT]
    checks.append({"context": CONTEXT, "app_id": GITHUB_ACTIONS_APP_ID})
    required = {"strict": True, "checks": checks}
    print(json.dumps({"branch": args.branch, "required_status_checks": required,
                      "enforce_admins": True, "apply": args.apply}, indent=2))
    if not args.apply:
        return
    if current is None or current.get("required_status_checks") is None:
        # PATCH cannot enable a missing status-check sub-protection. Preserve the
        # current reviews, restrictions and boolean protections in the full PUT.
        api(prefix, "PUT", protection_payload(current, required))
    else:
        api(prefix + "/required_status_checks", "PATCH", required)
        api(prefix + "/enforce_admins", "POST")
    verified = api(prefix)
    saved = verified["required_status_checks"]
    assert saved["strict"], "GitHub did not enable strict checks"
    assert any(check["context"] == CONTEXT and check["app_id"] == GITHUB_ACTIONS_APP_ID
               for check in saved["checks"]), "Required CI gate was not saved"
    assert verified["enforce_admins"]["enabled"], "Administrator enforcement was not saved"
    print("Verified: Required CI is required on " + args.branch)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, AssertionError) as error:
        raise SystemExit(str(error)) from None
