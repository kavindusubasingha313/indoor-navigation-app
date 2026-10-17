# NaviJac architecture

## Runtime and structure
NaviJac is a full-stack Jac 0.34.23 web application. Jac code provides both server endpoints and client components. The browser UI uses Jac JSX, React under the compiler runtime, React Router, Tailwind v4 and jac-shadcn primitives.

- `main.jac` is the app entry point. It imports endpoint symbols from `services.naviJacService` to register them and mounts a manual `<Router>` with routes for `/`, `/maps/sumanadasa/first-floor/route`, `/maps/sumanadasa/first-floor/edit`, `/creator`, and `/timetable`.
- `services/naviJacService.jac` is the server graph model/service module.
- `components/*.jac` contains client pages and reusable map/theme components.
- `components/ui/*.jac` contains jac-shadcn generated primitives.
- `styles/global.css` is Tailwind/theme CSS; `jac.toml` is project, dependency and client Vite configuration.
- `lib/utils.jac` holds shared UI class utilities.

## Backend and persistence
Jac OSP is the persistence model. The service declares graph nodes including `NaviJacMap`, `NaviJacFloor`, `NaviJacRoom`, `NaviJacGeometry`, `NaviJacCheckpoint`, `NaviJacWaypoint`, `NaviJacConnection`, `NaviJacAccount`, and `NaviJacTimetableEntry`. Public catalog data is read from `root.shared`; owned drafts and personal timetable entries use the caller's private root. Default local persistence is Jac's SQLite-backed `.jac/data/` store; that directory is generated/runtime data, not a distributable map asset.

Client components call server functions using `sv import` and `await`. Public functions use `def:pub`; owner-specific operations use protected/private endpoint declarations where present. `main.jac` must import endpoint symbols for API registration.

## APIs and functions
The service exposes map/catalog and floor reads, creator map create/update/publish/upload operations, editor and graph-validation operations, route search, timetable CRUD, and CSV validation/import. The current source includes no separate REST client or external map API integration. Names/signatures are visible in `services/naviJacService.jac` and the endpoint import list in `main.jac`.

## Routing algorithm
`find_verified_route` uses a Dijkstra-style weighted search over `NaviJacConnection` records. It requires source/destination `NaviJacCheckpoint` records that have coordinates and verified room-entrance status. Blocked edges are excluded; experimental proposals are eligible only when explicitly approved and experimental mode is enabled. This algorithm is implemented, but the featured Ground Floor has no seeded verified connection graph, so a successful route for that demo is not currently established.

A later UI attempt adds a “via lobby” demo path and a rough fixed distance. That is a client-side illustrative shortcut, not a graph-derived shortest path, and has not been verified end-to-end. Do not describe it as the service Dijkstra result.

## Map coordinates and source provenance
`NaviJacRoom.x/y`, geometry endpoints, checkpoints and waypoints are local map coordinates; they are not latitude/longitude. The current ground-floor UI is an inline SVG drawn in `components/NaviJacFloorMap.jac`; its room shapes and positions are hard-coded and approximate. The service room seed stores coarse dimension estimates from the supplied plan's printed dimension grid. It does not persist the SVG's room polygons, doorway positions, or route graph. The source PDF/image is not in the current repository listing. No permission/license record is available.

The plan grid should be treated as a user-authorized demo assumption, not an independently surveyed measurement. A real navigation deployment needs explicit scale calibration, common coordinate mapping, verified openings, room entrance nodes, accessible paths, provenance and review.

## GPS and current position
The UI includes a manual room/point selection concept and displays a location marker in the SVG. Source also contains a button whose response explains that browser GPS can only provide outdoor estimates and is not mapped to indoor floor coordinates. There is no evidence of a robust browser geolocation integration (permission request, timeout, accuracy rejection, proximity mapping) in the inspected route component. No BLE/QR/Wi-Fi positioning is implemented. Manual confirmed floor coordinates must not be represented as live GPS tracking.

## Authentication and ownership
The creator component calls Jac runtime signup/login/logout helpers. Owned maps are held under the authenticated user's graph and publication copies are placed in the shared catalog. Timetable operations are intended to be private. Authorization around admin verification is incomplete: featured demo editing methods are read-only/no-op, and owner approval of experimental edges is deliberately unavailable in the editor UI.

## Main dependencies
Declared in `jac.toml`: Jac/jac-scale runtime supplied by the environment; React 18, React Router, jac-shadcn UI dependencies, Tailwind CSS v4 and Vite plugin, Figtree and other fonts, plus form/chart/icon packages. Many declared npm dependencies are starter/template additions and may not be used by current code. Keep lock/install reproducibility for the target environment.
