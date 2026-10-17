# NaviJac agent instructions

## Project facts
- Full-stack Jac web application; tested/compiler target is Jac 0.34.23.
- Jac service/backend is in `services/naviJacService.jac`; React-compatible client JSX is written in `.jac` components under `components/`. Entry/router and endpoint registration are in `main.jac`.
- UI uses jac-shadcn components and Tailwind v4. Configuration and dependencies are in `jac.toml`.
- Persisted graph data is managed by Jac OSP. The default local store is under `.jac/data/` (generated/local; not source assets).

## Before changing code
1. Read `DEVELOPMENT_STATUS.md`, `ARCHITECTURE.md`, and `KNOWN_ISSUES.md`.
2. For Jac syntax, use the guides shipped with the exact installed CLI: `jac guide jac-core-cheatsheet`, `jac guide jac-types`, and relevant `jac guide jac-*` pages. Do not assume standard Python or JSX syntax is interchangeable with Jac.
3. Preserve all current routes and features unless a task explicitly changes them. Do not call an image-derived/demo route “verified” or an estimated dimension “surveyed.”
4. Do not activate graph edges or assert wheelchair accessibility based on the schematic alone. Keep outdoor GPS coordinates distinct from local floor-plan coordinates.
5. Client components use `has` fields for reactive state and `async can with entry` for mount loading. Keep hooks in the same order on every render; do not place state declarations or hooks behind conditionals. Await every client `sv import` call.
6. Jac `node`/`edge` schema changes may interact with persisted `.jac/data`; use additive/defaulted schema evolution and preserve existing records.

## Layout
- `main.jac`: manual React Router routes and imported endpoint registration.
- `services/naviJacService.jac`: graph models, public functions, map/user/timetable operations and route algorithm.
- `components/NaviJacHome.jac`: public map directory/landing page.
- `components/NaviJacFloorMap.jac`: inline SVG ground-floor schematic.
- `components/NaviJacRouteFinder.jac`: visitor route view and positioning controls.
- `components/NaviJacFloorEditor.jac`: experimental editor/graph status UI.
- `components/NaviJacCreator.jac`: creator account and owned-map workspace.
- `components/NaviJacTimetable.jac`: private timetable and CSV preview/import UI.
- `components/NaviJacThemeToggle.jac`: theme control.
- `components/ui/`: generated jac-shadcn primitives; import and compose, do not hand-edit these managed components.

## Commands
From the project root, with Jac 0.34.23 installed:
```sh
jac install
jac check main.jac
jac start --dev main.jac
```
The IDE preview is platform-managed; do not start or kill another server in that environment. Run automated tests with `jac test` only after adding/locating test files; this checkout currently contains no `*.test.jac` files. A production build command has not been confirmed for this checkout; consult `jac --help` for the installed CLI rather than assuming a command.

## Environment and secrets
`jac.toml` references `OPENAI_API_KEY` and `LLM_MODEL` for optional by-LLM configuration; current NaviJac code does not need an LLM to render. Do not commit `.env`, credentials, tokens, or keys. Configure secrets through the local environment/IDE Settings. No database initialization is needed for the default local Jac graph store; protect backups before resetting `.jac/data/`.

## Compatibility and quality
- Keep route paths and imported endpoint names registered in `main.jac` in sync.
- Follow `jac-cl-components`, `jac-fullstack-patterns`, `jac-sv-persistence`, and `jac-sv-endpoints` for cross-boundary changes.
- Keep mobile layout responsive; use semantic theme tokens and existing components.
- Check the actual rendered screen at phone and desktop widths after UI changes. Report test commands/results honestly.
- Never claim GPS is indoor positioning. Never present the demo’s estimated map-derived distances as measured walking distances.
