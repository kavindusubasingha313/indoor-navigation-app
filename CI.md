# Continuous integration and code review

## What runs

`.github/workflows/ci.yml` runs on every push and on pull-request creation,
reopening, and new commits (`synchronize`), including draft PRs. It also supports
manual runs and merge-queue checks. There are no path filters that could leave a
required check pending. New pushes cancel obsolete runs for the same PR/ref.

| Check | Scope |
| --- | --- |
| Jac compiler and lint | `jac check` and `jac lint` over both entry files, components, services, and utilities; both commands run even when one fails |
| Navigation graph tests | Seven Jac tests invoke the production route function with real stored synthetic graphs: weighted shortest path, blocked/unverified edges, experimental approval plus opt-in, directed edges, floor isolation, and missing endpoints |
| Map persistence and authorization | Real HTTP requests, registration/login, map retention across a server-process restart, ownership isolation, anonymous access rejection, publish/unpublish visibility, and repeatable demo initialization |
| Frontend build and browser tests | Actual `main.jac` build plus Chromium checks for home rendering, persistent theme changes, room loading/manual confirmation, and mobile overflow |
| **Required CI** | Fails unless all four preceding jobs succeed; failed, cancelled, or skipped jobs cannot make this gate pass |

The graph suite is run through a pytest wrapper, which requires all seven Jac
tests to execute. Its JUnit report has one wrapper case; `-rA` includes the
underlying seven test results in the job log. No zero-test run counts as success.
There was no existing automated test suite when this configuration was added.
These tests add coverage; they are not evidence that all application flows work.

Tests use disposable copies under the system temporary directory. They do not
delete or reuse the checkout's `.jac/data`, create real maps on a deployed server,
or activate routes in the featured demo. Accounts/passwords are generated only
for the temporary test server and are not printed or saved as artifacts.

## Toolchain and local commands

CI uses Ubuntu 24.04, Python 3.12 and Node 22. `ci/requirements.txt` pins the
published Python toolchain and resolved test dependencies, including Jac 0.16.7,
jac-client 0.3.25, jac-scale 0.2.31, and requests (required by the scale plugin).
The handover documents refer to Jac **0.34.23**, which was not available from
PyPI when checked. Do not silently substitute that unavailable version in CI.
The published toolchain exposes existing compatibility failures described below.

```sh
python3.12 -m venv .venv
. .venv/bin/activate
python -m pip install -r ci/requirements.txt
jac install --dev
python ci/check_jac.py
python -m pytest tests/test_navigation.py -vv -rA
python -m pytest tests/test_persistence.py -vv --tb=short
python -m playwright install --with-deps chromium
jac build main.jac
python -m pytest tests/test_frontend.py -vv --tb=short
```

For a local system Chromium, set `NAVIJAC_CHROMIUM_EXECUTABLE` to its executable
path. Otherwise Playwright uses its pinned browser. npm dependencies remain
declared by `jac.toml` and installed through Jac; their existing version ranges
are not a frozen npm dependency graph. A future package update should establish
a repository-supported frozen client lockfile rather than silently rewriting
the application dependencies here.

## Inspecting failures

1. On a PR, open **Checks**, then the failing job's **Details**. Alternatively,
   open the repository's **Actions** tab and select **NaviJac CI** and the commit.
2. Read the failed step and its assertions. Test jobs publish counts and failing
   test names in the run summary and produce error annotations. Compiler/lint
   diagnostics are retained even if another check fails.
3. Download the matching `navigation-results`, `persistence-results`,
   `frontend-results`, or `compiler-diagnostics` artifact. Test artifacts include
   JUnit XML; frontend artifacts include the build log and browser traces or
   screenshots when a browser reached the page. Artifacts expire after seven days.
4. Use `python -m playwright show-trace path/to/trace.zip` to inspect a saved trace.
   Server-startup failures happen before browser actions, so they may have no trace.
5. Reproduce the failing command locally. Fix the underlying defect and push a
   new commit; PR checks rerun automatically. Authorized maintainers can also use
   **Re-run failed jobs**. Do not skip, xfail, or remove assertions merely to merge.

Failures caught at introduction (not suppressed): map unpublication returned
the unpublished shared record to anonymous callers; featured-floor seeding
raised a list/node error; `main.jac` used client-only imports in server context
under the pinned published toolchain. Compiler/lint results and exact browser
startup diagnostics are separate from navigation/service test results. The runtime
repair commit fixes these defects; local compiler/lint, bundling, and all 14 pytest
cases now pass (including seven nested Jac graph tests). Browser coverage now also
includes creator publication/unpublication and timetable saves after reload.

## Protecting main

Repository settings are not activated by committing a workflow file. After a
test PR has registered the checks, an administrator should require **Required CI**
from **GitHub Actions**, require the branch to be up to date, and enforce the
requirement for administrators. Retain all existing stronger rules and any
existing required checks/reviews.

An administrator can inspect the additive change and then apply it:

```sh
python ci/configure_branch_protection.py
python ci/configure_branch_protection.py --apply
```

The script verifies repository admin permission, preserves unrelated existing
required status checks, updates only the relevant protection endpoints when
protection exists, and reads back the result. Review-only protection without an
existing status-check sub-protection uses a full PUT retaining its reviews,
restrictions, and boolean settings; a regression test covers this case. It binds `Required CI` to the GitHub
Actions app. It never runs in CI and needs no administrator token in Actions.
Existing rulesets/bypass grants are outside this script; inspect them in
**Settings → Rules → Rulesets** as well. Protection availability depends on the
repository plan and permissions. A failed API operation does not establish that
protection is enabled.

## Codex pull-request reviews

Codex automatic reviews are managed through the Codex GitHub integration, not by
this Actions file or a repository JSON flag. A repository administrator or an
authorized Codex user must connect the repository and enable automatic reviews
in Codex's code-review settings. If the account offers review of **new pushes**
or **every push**, enable it for this repository too. GitHub's `synchronize`
trigger reruns CI; it does not itself request another Codex review.

See the official guide:
<https://developers.openai.com/codex/integrations/github/>.

To request another review on a PR where the integration has access, post:

```text
@codex review
```

Confirm that Codex responds on the intended latest commit. `AGENTS.md` includes
review guidelines for navigation, ownership, visibility, and persistence. Those
guidelines do not enable the integration. A Codex review is advisory here; it is
not substituted for the required CI gate. No OpenAI key is passed to PR code.

## Safe pull-request verification

Use a dedicated branch and a **draft** PR targeting `main`; never merge it as a
test. Push a second harmless documentation commit to confirm `synchronize`
starts a new run. Inspect the individual checks and `Required CI` on the latest
SHA, then inspect the main-branch protection/merge status without merging.
Existing unsuppressed failures should make the gate red and block a protected
merge. Once the app is repaired, a separate throwaway branch can introduce a
temporary failing assertion, verify a red check, then restore it and verify green.
Do not merge a deliberately failing assertion or disable a gate to finish setup.

Verify Codex separately: enable its supported repository settings, request a
review if needed, and confirm a review of the latest SHA after another push.
Draft PRs may need a manual `@codex review` request depending on integration
behavior. An Actions run is not proof that Codex reviewed the PR.

## Security

- Hosted runners, read-only `contents` permission, and non-persistent checkout credentials.
- Actions pinned to full commit SHAs; Python dependencies pinned to exact versions.
- `pull_request` rather than `pull_request_target`; no write-token job executes fork code.
- No application secrets, production services, deployments, auto-merge, or PR-comment bot tokens.
- Artifacts include only explicit diagnostics/test results, never graph databases, environment dumps, or credential files.
- Dependency installation uses normal TLS and package integrity checks; verification is not disabled.

## Activation status

Local verification and GitHub-hosted verification are separate. Draft
[PR #1](https://github.com/kavindusubasingha313/indoor-navigation-app/pull/1)
verified both push and PR events. The initial hosted run
[39024105131](https://github.com/kavindusubasingha313/indoor-navigation-app/actions/runs/39024105131)
passed graph tests and failed the other application checks; Required CI correctly
failed. The app defects were subsequently repaired without suppressing tests.

The native Codex integration completed a manual review of commit `0968cef` and
provided a finding that was addressed. Its automatic/new-push settings cannot be
changed through the available APIs, so they are not claimed enabled. Review
configuration is at <https://chatgpt.com/codex/cloud/settings/general>.

GitHub reports repository-admin membership, but the integration returns HTTP 403
for branch-protection operations. The rulesets API also reports that this private
repository needs GitHub Pro to enable that feature. Main-branch merge enforcement
is therefore not enabled by this change; the owner must resolve plan/access limits
and apply the documented gate. No merge or public deployment occurred as part of
the CI verification.
