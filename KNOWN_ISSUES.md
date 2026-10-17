# Known issues and verification limits

## Navigation and plan geometry
- The current ground-floor floorplan is a manually authored SVG schematic in `components/NaviJacFloorMap.jac`, not an imported/registered source PDF or CAD drawing.
- Room dimensions in the ground-floor seed are approximate bounding values. The 6 m printed grid is used as a demo-scale assumption; no source survey/calibration is included.
- The repository listing does not contain the supplied PDF/image, a rights/license statement, or a digitized geometry asset. Confirm permission and provenance before committing the source drawing.
- The ground-floor seed does not set room coordinates, checkpoint placement or graph connections. `get_floor_editor_data` can create unplaced checkpoints; these do not provide walkable route connectivity.
- The service Dijkstra implementation only searches eligible stored graph edges and needs confirmed entrance endpoints. The featured ground-floor graph is empty/unverified, so the algorithm cannot presently demonstrate a real route through the Library.
- Route page source has undergone recent experimental edits for selectable rooms and “via lobby” instructions. Prior browser testing observed a React hook-order exception and a `select_destination is not defined` error; later validation surfaced earlier/stale Vite and hook warnings. The latest route interaction is not confirmed to produce directions. Re-test from a clean server/cache before continuing.
- The fixed “12 m/24 m” route estimate is illustrative logic, not a geometry-derived shortest distance and must not be presented as a measured walking distance.
- Room entrances, doorway widths, stairs/lift access, corridors and accessible circulation have not been verified. No safety/accessibility guarantee is possible.
- Route header, route paths and editor labels still contain `first-floor` path segments or stale First Floor defaults even though the featured seeded floor is Ground Floor. Migrate route slugs and legacy data carefully.
- The previously implemented Electrical Engineering First Floor data/graph is not evident in the current 14-room ground-floor seed and should be independently checked before removal or restoration.

## Positioning
- No confirmed automatic indoor tracking exists. BLE, QR, Wi-Fi and similar sources are not implemented.
- Phone GPS is not equivalent to indoor map coordinates; the route screen has only explanatory copy, not a verified proximity/permission workflow.
- Manual selection, marker, centering and route recalculation have not passed an end-to-end browser test. Current marker coordinates are fixed SVG positions, not per-room coordinates.

## Creator, editor, timetable
- Creator account and ownership UI/service paths exist but have not been tested end to end in this handover.
- Featured floor editor operations are read-only/no-op. Other save methods/authorization should be checked before offering editing to users.
- No configured admin role/approval workflow has been established for real edge verification. Experimental proposal approval is disabled in UI.
- Timetable manual form and CSV code exist; authentication, import semantics, overlaps, and persistence were not tested end to end in this handover.
- Map upload accepts bounded PNG/JPEG base64 to owned maps, but no evidence confirms coordinate alignment or published asset view lifecycle.

## Tests/tooling and repository handover
- `jac check main.jac` passes, but emits W1100/W1051 warnings related to runtime `react-router-dom` resolution and route component types. It does not prove the Vite browser bundle works.
- No `*.test.jac` files or checked-in test commands were found in the project listing. Automated test suite status: absent/unverified.
- Earlier managed browser results included successful responsive rendering/no phone overflow but also JavaScript errors during route state updates. No clean successful route interaction is established.
- Git commands fail with “not a git repository” in the provided workspace shell. No remote URL, branch, commit hash, clean status, tracked asset inventory, commit, or push could be verified.
- This checkout has no original PDF/map asset. Do not invent the association between a future asset and current SVG/graph; add provenance IDs and verification metadata when available.
- No exact production build command is documented. Check the installed Jac CLI before defining CI.
