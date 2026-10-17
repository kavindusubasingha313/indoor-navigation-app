# NaviJac

NaviJac is a Jac full-stack indoor map and navigation prototype. It contains a public map directory, a featured University of Moratuwa Library Ground Floor schematic, an experimental graph editor, creator-owned map flows, a personal timetable, and theme controls.

**Navigation status:** the current Library plan is a demo reconstruction from a supplied overhead image. Dimensions use a printed-grid assumption, while actual entrance geometry, accessibility and walking routes remain unverified. Do not rely on it for real-world navigation. The illustrative route-selection flow, manual confirmation, creator drafts, and timetable saves are covered by browser tests; the underlying floor geometry remains unverified.

## Requirements and run
Use Jac 0.16.7. From this directory:
```sh
python -m pip install -c ci/requirements.txt -r requirements.txt
jac install --dev
jac check main.jac
jac start --dev main.jac
```
Open the URL emitted by Jac. Environment variables, tests, architecture and known limitations are described in [SETUP.md](SETUP.md), [ARCHITECTURE.md](ARCHITECTURE.md), [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md), and [KNOWN_ISSUES.md](KNOWN_ISSUES.md). Codex-specific instructions are in [AGENTS.md](AGENTS.md).

## Current routes
- `/` — public map directory/home.
- `/maps/sumanadasa/first-floor/route` — featured ground-floor visitor demo (legacy URL slug).
- `/maps/sumanadasa/first-floor/edit` — experimental editor (legacy URL slug).
- `/creator` — creator account and map workspace.
- `/timetable` — personal timetable.

## Project layout
- `main.jac` — full-stack entry and manual router.
- `services/naviJacService.jac` — graph models and service functions.
- `components/` — pages, floor map, theme; `components/ui/` — managed shadcn primitives.
- `styles/global.css`, `jac.toml` — theme, Tailwind/Vite and dependencies.

## Tests, review, and deployment
Run `python -m pip install -r ci/requirements.txt`, then `python -m pytest tests -vv`.
The pytest suite includes seven Jac graph cases, process-restart persistence,
ownership/publication checks, production-key checks, and Chromium browser flows.
See [CI.md](CI.md) for browser setup, failure artifacts, branch protection and
requesting Codex review. See [DEPLOYMENT.md](DEPLOYMENT.md) for the production
container and persistent-storage requirements. No workflow automatically merges
or deploys the application.
