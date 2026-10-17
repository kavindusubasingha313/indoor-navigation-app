# NaviJac

NaviJac is a Jac full-stack indoor map and navigation prototype. It contains a public map directory, a featured University of Moratuwa Library Ground Floor schematic, an experimental graph editor, creator-owned map flows, a personal timetable, and theme controls.

**Navigation status:** the current Library plan is a demo reconstruction from a supplied overhead image. Dimensions use a printed-grid assumption, while actual entrance geometry, accessibility and walking routes remain unverified. Do not rely on it for real-world navigation. The route-selection UI is under development and its end-to-end interaction is not currently verified.

## Requirements and run
Use Jac 0.34.23. From this directory:
```sh
jac install
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

## Testing caveat
`jac check main.jac` passed during handover with existing warnings. No Jac test files were found. The browser route interaction has known errors and is not signed off. See the status and issue documents before using the demo or continuing implementation.
