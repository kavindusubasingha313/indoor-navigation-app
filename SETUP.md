# NaviJac setup

## Requirements
- Jac CLI **0.34.23** (or the compatible project release); verify with `jac --version`.
- Node/npm support as managed by Jac for client dependencies.
- A local checkout of this project, including `jac.toml`.

## Install
From the repository root:
```sh
jac install
```
This installs/resolves the Jac project dependencies from `jac.toml`, including client dependencies.

## Environment variables
No environment variable is required by the inspected routing/map code for a basic local run. `jac.toml` defines optional LLM interpolation:
- `OPENAI_API_KEY` (optional; no current NaviJac screen needs an LLM)
- `LLM_MODEL` (optional, defaults in config to `gpt-4o-mini`)

Set secrets in the local shell or an IDE environment settings panel. Never commit actual keys, auth tokens, `.env` values, or passwords. No separate database URL is required for default local graph persistence. Jac uses its local data store under `.jac/data/`; do not delete it unless intentionally resetting local development data.

## Initialize and run
The Jac graph database initializes as the application accesses it; no separate migration/init command is documented in this repository.
```sh
jac start --dev main.jac
```
Open the URL printed by the CLI (commonly `http://localhost:8000`). In the JacHammer workspace, the preview server is platform-managed; do not start, kill, or replace it manually.

## Checks and tests
```sh
jac check main.jac
jac test
```
The compiler check was run for this handover and passed with runtime import/type warnings. `jac test` is the expected Jac test runner, but this checkout currently has no test files, and the command was not run during this handover. No integration or automated browser test script is checked into the source tree.

For manual browser checks, use the app URL and verify the home route, visitor route, creator flow, timetable flow and editor. Test both narrow phone and desktop widths. Do not report a flow as passing unless it was exercised; the route selection flow is currently known to need retesting.

## Build
There is no confirmed production build command or build script recorded in `jac.toml`/the repository docs. Consult `jac --help` for the installed Jac release before choosing one. Do not treat `jac check` as a production bundle build.

## Local backend/frontend distinction
`main.jac` starts the full-stack application; the frontend is built/served by Jac's client pipeline. There is no separate backend service command or separately maintained frontend package manifest in the source tree.
