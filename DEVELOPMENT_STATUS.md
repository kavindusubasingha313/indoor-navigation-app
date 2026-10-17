# NaviJac development status

Updated: 2026-05-04

## Summary
NaviJac is an existing Jac full-stack web application with a public map directory, creator workspace, personal timetable, theme control, experimental floor editor, graph-routing service, and a Library Ground Floor schematic demo. This status reflects source inspection and checks performed for the current handover. Historical stage labels below are reconstructed from the surviving source and agent notes; there is no complete change log in this workspace.

## Stages 1–7
- **Stages 1–4 — foundation and map/creator work: partially evidenced.** The code contains the route shell, public map catalog, graph models, a creator account/map ownership workflow, upload API, and editor UI. The original stage specifications and formal acceptance results are not present, so those stages cannot be certified complete here.
- **Stage 5 — timetable and theme: implemented in source, not fully regression-tested.** The app has a theme toggle and private timetable data/UI, including manual session validation and CSV preview/import functions. Authentication-dependent end-to-end behavior was not tested during this handover.
- **Stage 6 — graph routing/editor groundwork: partially implemented.** The service contains Dijkstra-style routing over existing eligible graph edges and requires confirmed room entrance checkpoints. The editor exposes point/edge controls and validation UI; featured demo save functions are read-only/no-op and no verified ground-floor graph is seeded. Owner/admin authorization for approving experimental edges is not complete.
- **Stage 7 — visual Library Ground Floor and manual positioning: partial/demo only.** Room labels and approximate dimensions are seeded, and `NaviJacFloorMap.jac` renders an inline SVG reconstruction. The route page has manual point selection controls, but an interactive start-to-destination route has not been verified and the latest attempted implementation has reported runtime errors in earlier preview checks. The graphic is not the original PDF/CAD; the PDF is not present in the repository. Do not mark turn-by-turn routing complete.

## Implemented in inspected source
- Jac manual router with home, featured route/editor, creator, timetable paths.
- Jac graph archetypes for maps, floors, rooms, checkpoints, waypoints, connections, accounts and timetable entries.
- Public/shared map reads; creator-owned draft CRUD/publish flow with Jac auth helpers; bounded PNG/JPEG upload endpoint.
- Dijkstra route function over eligible stored graph connections, with verified-only default and experimental mode option.
- Personal timetable entries with overlap/time validation and CSV parse/preview/import service functions.
- Light/dark/system theme UI.
- Responsive SVG ground-floor sketch and a seeded list of rooms from the supplied plan.

## Partial or not implemented
- Original floor-plan PDF/CAD import or calibrated coordinate registration.
- Persisted measured room outlines, door locations, corridor geometry, or connected ground-floor graph.
- Graph routing for every Library room, route overlay on actual map coordinates, reliable route distance or step-by-step instructions.
- Working, browser-verified position-update/recalculate loop.
- Actual smartphone geolocation permission, timeout, low-accuracy handling, and GPS-to-building proximity integration.
- BLE, QR, Wi-Fi, or other indoor positioning.
- Verified entrance accessibility, lifts, stairs, door clear widths, and accessible route network.
- Full multi-floor support/route UI for arbitrary creator maps.
- Existing Electrical Engineering First Floor demonstration is not in the currently visible 14-room ground-floor seed; prior route/editor source still contains stale First Floor labels/defaults. Whether its full data exists is unknown.

## Latest verification
- `jac check main.jac`: **passed** on 2026-05-04 (1 pass). Existing W1100/W1051 warnings about `react-router-dom`/runtime bindings were emitted. The check is not a runtime or integration test.
- Managed preview had previously rendered the ground-floor route at phone and desktop widths with no phone overflow. Earlier selection tests produced React hook-order errors and a `select_destination` ReferenceError; a later screenshot showed stale/older errors and no selected route. Current source changes after that screenshot have not received a clean successful route interaction test. Treat browser route status as **unverified**.
- `jac test`: not run; no test files were found.
- Git status/remotes/commit: unavailable from the provided shell context (Git reports this workspace is not a repository). No commit/push was made.

## Recommended Stage 8 priorities (not implemented)
1. Stabilize the route page and add tests for start/destination state, route recalculation, and impossible routes.
2. Obtain permission to store the source drawing; add the original asset and record its provenance/license.
3. Digitize/validate dimensions, doorways, stairs/lifts, walkable areas, and per-room entrance coordinates with an on-site reviewer.
4. Connect the graph to coordinate geometry, compute shortest paths, draw route polylines, and derive distance from calibrated coordinates.
5. Complete GPS permission/error handling and keep outdoor proximity separate from indoor positioning.
6. Add auth/authorization tests for creator edits, publishing, and reviewer verification.
7. Set up CI, automated Jac tests, browser flows, and an actual Git remote/branch handover.
