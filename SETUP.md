# NaviJac setup

## Requirements
- Jac CLI **0.16.7** (or the compatible project release); verify with `jac --version`.
- Node/npm support as managed by Jac for client dependencies.
- A local checkout of this project, including `jac.toml`.

## Install
From the repository root, in a Python 3.12 virtual environment:
```sh
python -m pip install -c ci/requirements.txt -r requirements.txt
jac install --dev
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
python -m pip install -r ci/requirements.txt
python ci/check_jac.py
python -m playwright install --with-deps chromium
python -m pytest tests -vv
jac build main.jac
```
The suite runs in temporary copies and preserves the checkout's graph data.
It checks seven Jac graph scenarios, actual server restarts and ownership,
publication visibility, production signing keys, and browser interactions.
`jac check` alone is not an application or browser test. See [CI.md](CI.md).

## Production
Use the Dockerfile and [DEPLOYMENT.md](DEPLOYMENT.md). The production entry point
runs without hot reload, disables the bundled default admin portal, and persists
a private session-signing key with the graph data. Mount persistent storage at
`/app/.jac/data` and terminate HTTPS at the hosting service. No public deployment
is established by a local build.
