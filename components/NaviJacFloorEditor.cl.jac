import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.badge { Badge }
import from .NaviJacThemeToggle { NaviJacThemeToggle }
import from "@jac/runtime" { Link, jacIsLoggedIn }
sv import from ..services.naviJacService { NaviJacFloor, NaviJacRoom, NaviJacGeometry, NaviJacCheckpoint, NaviJacWaypoint, NaviJacConnection, seed_sumanadasa_floor, get_floor_editor_data, save_floor_editor_changes, calibrate_floor_scale, save_checkpoint_placement, save_corridor_waypoint, save_connection_edge, verify_connection_edge, get_graph_validation_summary, bulk_approve_experimental_edges }

def:pub NaviJacFloorEditor() -> JsxElement {
    has floor_id: str = "",
        floor: NaviJacFloor | None = None,
        rooms: list[NaviJacRoom] = [],
        geometry: list[NaviJacGeometry] = [],
        checkpoints: list[NaviJacCheckpoint] = [],
        waypoints: list[NaviJacWaypoint] = [],
        connections: list[NaviJacConnection] = [],
        selected_room_id: str = "",
        length_text: str = "14.0",
        width_text: str = "6.4",
        label_text: str = "Electrical Engineering seminar room",
        feedback: str = "",
        loading: bool = True,
        show_geometry: bool = True,
        show_labels: bool = True,
        known_distance: str = "14",
        pixel_distance: str = "154",
        coordinate_x: str = "",
        coordinate_y: str = "",
        waypoint_label: str = "",
        from_id: str = "",
        to_id: str = "",
        graph_summary: dict = {};

    async can with entry {
        seeded_floor_id = await seed_sumanadasa_floor();
        floor_id = seeded_floor_id;
        refresh_data(seeded_floor_id);
    }

    async def refresh_data(load_floor_id: str) -> None {
        data = await get_floor_editor_data(load_floor_id);
        floor = data["floor"] as NaviJacFloor;
        rooms = data["rooms"] as list[NaviJacRoom];
        geometry = data["geometry"] as list[NaviJacGeometry];
        checkpoints = data["checkpoints"] as list[NaviJacCheckpoint];
        waypoints = data["waypoints"] as list[NaviJacWaypoint];
        connections = data["connections"] as list[NaviJacConnection];
        graph_summary = await get_graph_validation_summary(load_floor_id);
        if len(rooms) > 0 and len(selected_room_id) == 0 {
            selected_room_id = jid(rooms[0]);
            length_text = str(rooms[0].length_m);
            width_text = str(rooms[0].width_m);
            label_text = rooms[0].display_label;
        }
        loading = False;
    }

    def select_room(room_id: str) {
        selected_room_id = room_id;
        for r in rooms {
            if jid(r) == room_id { length_text = str(r.length_m); width_text = str(r.width_m); label_text = r.display_label; }
        }
    }
    def update_length(e: ChangeEvent) { length_text = e.target.value; }
    def update_width(e: ChangeEvent) { width_text = e.target.value; }
    def update_label(e: ChangeEvent) { label_text = e.target.value; }
    def update_known(e: ChangeEvent) { known_distance = e.target.value; }
    def update_pixels(e: ChangeEvent) { pixel_distance = e.target.value; }
    def update_x(e: ChangeEvent) { coordinate_x = e.target.value; }
    def update_y(e: ChangeEvent) { coordinate_y = e.target.value; }
    def update_waypoint_label(e: ChangeEvent) { waypoint_label = e.target.value; }
    def update_from(e: ChangeEvent) { from_id = e.target.value; }
    def update_to(e: ChangeEvent) { to_id = e.target.value; }
    def toggle_geometry(e: ChangeEvent) { show_geometry = e.target.checked; }
    def toggle_labels(e: ChangeEvent) { show_labels = e.target.checked; }

    async def save_room -> None {
        if len(selected_room_id) == 0 { feedback = "Select a room before saving."; return; }
        result = await save_floor_editor_changes(floor_id, selected_room_id, float(length_text), float(width_text), 10.0, 10.0, label_text, "", 0.0, 0.0, 0.0, 0.0);
        feedback = result["message"] as str;
        refresh_data(floor_id);
    }

    async def place_checkpoint(confirm_entrance: bool) -> None {
        if len(selected_room_id) == 0 { feedback = "Choose a room before placing a checkpoint."; return; }
        result = await save_checkpoint_placement(floor_id, selected_room_id, float(coordinate_x), float(coordinate_y), confirm_entrance);
        if result is None { feedback = "Coordinates must be from 0 to 100."; } elif confirm_entrance { feedback = "Entrance confirmed. It will route only through verified graph edges."; } else { feedback = "Checkpoint coordinates saved; entrance remains unverified."; }
        refresh_data(floor_id);
    }

    async def add_waypoint -> None {
        result = await save_corridor_waypoint(floor_id, waypoint_label, float(coordinate_x), float(coordinate_y));
        if result is None { feedback = "Coordinates must be from 0 to 100."; } else { feedback = "Corridor waypoint saved without activating a route."; }
        refresh_data(floor_id);
    }

    async def connect_points -> None {
        result = await save_connection_edge(floor_id, from_id, to_id, 1.0);
        if result is None { feedback = "Choose two different placed checkpoints or saved waypoints."; } else { feedback = "Connection saved as unverified and excluded from visitor routes."; }
        refresh_data(floor_id);
    }

    async def verify_edge(edge_id: str, currently_verified: bool) -> None {
        updated = await verify_connection_edge(edge_id, not currently_verified, False);
        if updated is None { feedback = "Connection could not be found."; } elif currently_verified { feedback = "Connection returned to unverified status."; } else { feedback = "Connection marked verified. Confirm this path on the actual floor plan before public use."; }
        refresh_data(floor_id);
    }

    async def calibrate -> None {
        result = await calibrate_floor_scale(floor_id, float(known_distance), float(pixel_distance));
        feedback = result["message"] as str;
        refresh_data(floor_id);
    }

    async def approve_proposals -> None {
        if not jacIsLoggedIn() { feedback = "Sign in as the map owner to approve experimental proposals."; return; }
        result = await bulk_approve_experimental_edges("sumanadasa-featured");
        feedback = result["message"] as str;
        refresh_data(floor_id);
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur"><div className="mx-auto flex max-w-[1600px] flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6"><div className="flex items-center gap-3"><Link to="/" className="text-sm text-muted-foreground hover:text-foreground">NaviJac</Link><span>/</span><span className="font-semibold">First-floor editor</span></div><div className="flex items-center gap-3"><Badge variant="outline">Experimental workspace</Badge><NaviJacThemeToggle /></div></div></header>
        <main className="mx-auto flex w-full max-w-[1600px] flex-col gap-5 px-4 py-5 sm:px-6">
            <section className="flex flex-wrap items-end justify-between gap-4"><div className="flex flex-col gap-1"><h1 className="text-2xl font-semibold tracking-tight">{floor.building_name if floor else "Dr. L. H. Sumanadasa Building"} · {floor.floor_name if floor else "First Floor"}</h1><p className="text-sm text-muted-foreground">Electrical Engineering · University of Moratuwa</p></div><Button onClick={save_room}>Save room changes</Button></section>
            <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950"><p className="font-semibold">Estimated plan; not verified architectural measurements</p><p className="mt-1">Room 1’s 14 m horizontal span corresponds to approximately 154 px in the supplied schematic. A single reference does not establish uniform scale. Do not use for construction, accessibility clearances, or accurate travel times. No doors or walkable paths have been inferred.</p></div>
            {if loading { <p className="rounded-lg border bg-card p-5 text-sm text-muted-foreground">Loading floor and graph records…</p> }}
            <div className="grid min-w-0 gap-5 xl:grid-cols-[minmax(0,1fr)_22rem]">
                <Card className="min-w-0 shadow-sm">
                    <CardHeader className="flex flex-wrap items-start justify-between gap-3"><div><CardTitle>Room checkpoints and sketch</CardTitle><CardDescription>Checkpoints stay pending until coordinates and the real entrance are confirmed. No suggested edges are active by default.</CardDescription></div><div className="flex gap-2"><label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={show_geometry} onChange={toggle_geometry} />Sketch</label><label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={show_labels} onChange={toggle_labels} />Labels</label></div></CardHeader>
                    <CardContent className="flex flex-col gap-4">
                        <div className="overflow-auto rounded-lg border bg-background p-2"><svg viewBox="0 0 1000 480" className="block h-auto min-h-[320px] w-full" role="img" aria-label="Experimental floor sketch with room checkpoints">
                            {if show_geometry { <rect x="20" y="45" width="960" height="390" rx="10" fill="none" stroke="currentColor" strokeWidth="3" /> }}
                            {if show_geometry {
                                for (index, room) in enumerate(rooms) {
                                    <g key={jid(room)} onClick={lambda { select_room(jid(room)); }} className="cursor-pointer"><rect x={str(30 + (index % 7) * 134)} y={str(65 + (index / 7) * 115)} width="120" height="92" rx="6" fill={"#ede9fe" if jid(room) == selected_room_id else "#f5f5f4"} stroke={"#6d28d9" if jid(room) == selected_room_id else "#a8a29e"} strokeWidth="2" />{if show_labels { <text x={str(38 + (index % 7) * 134)} y={str(91 + (index / 7) * 115)} fontSize="12">{"Room " + str(room.room_number)}</text> }}{if show_labels { <text x={str(38 + (index % 7) * 134)} y={str(111 + (index / 7) * 115)} fontSize="10">{room.display_label}</text> }}</g>
                                }
                            }}
                            {for cp in checkpoints { if cp.coordinate_set { <circle key={jid(cp)} cx={str(cp.x * 9.6 + 20)} cy={str(cp.y * 3.9 + 45)} r="8" fill="#d97706" /> } }}
                            {for w in waypoints { <circle key={jid(w)} cx={str(w.x * 9.6 + 20)} cy={str(w.y * 3.9 + 45)} r="7" fill="#0f766e" /> }}
                            {for edge_record in connections {
                                for a in waypoints {
                                    for b in waypoints {
                                        if jid(a) == edge_record.from_id and jid(b) == edge_record.to_id {
                                            <line key={jid(edge_record)} x1={str(a.x * 9.6 + 20)} y1={str(a.y * 3.9 + 45)} x2={str(b.x * 9.6 + 20)} y2={str(b.y * 3.9 + 45)} stroke={"#15803d" if edge_record.verification_status == "Verified" else "#d97706"} strokeDasharray={"" if edge_record.verification_status == "Verified" else "8 5"} strokeWidth="4" />
                                        }
                                    }
                                }
                            }}
                        </svg></div>
                        <Card className="shadow-none"><CardHeader><CardTitle>Manual point placement</CardTitle><CardDescription>Enter normalized coordinates based on the real uploaded plan. This sketch is not the original plan and does not certify an entrance.</CardDescription></CardHeader><CardContent className="grid gap-3 sm:grid-cols-2"><label className="flex flex-col gap-1 text-sm">X (0–100)<Input type="number" min="0" max="100" step="0.1" value={coordinate_x} onChange={update_x} /></label><label className="flex flex-col gap-1 text-sm">Y (0–100)<Input type="number" min="0" max="100" step="0.1" value={coordinate_y} onChange={update_y} /></label><Button variant="outline" onClick={lambda { place_checkpoint(False); }}>Save pending checkpoint</Button><Button variant="outline" onClick={lambda { place_checkpoint(True); }}>Confirm room entrance</Button><label className="flex flex-col gap-1 text-sm">Waypoint label<Input value={waypoint_label} onChange={update_waypoint_label} placeholder="Corridor junction" /></label><Button variant="outline" onClick={add_waypoint}>Add corridor waypoint</Button></CardContent></Card>
                        <Card className="shadow-none"><CardHeader><CardTitle>Connect graph points</CardTitle><CardDescription>New connections remain unverified and are excluded from visitor routes.</CardDescription></CardHeader><CardContent className="grid gap-3 sm:grid-cols-2"><label className="flex flex-col gap-1 text-sm">From point<select className="h-10 rounded-md border bg-background px-3" value={from_id} onChange={update_from}><option value="">Choose point</option>{for cp in checkpoints { if cp.coordinate_set { <option key={jid(cp)} value={jid(cp)}>Room {cp.room_number}</option> } }}{for w in waypoints { <option key={jid(w)} value={jid(w)}>{w.label}</option> }}</select></label><label className="flex flex-col gap-1 text-sm">To point<select className="h-10 rounded-md border bg-background px-3" value={to_id} onChange={update_to}><option value="">Choose point</option>{for cp in checkpoints { if cp.coordinate_set { <option key={jid(cp)} value={jid(cp)}>Room {cp.room_number}</option> } }}{for w in waypoints { <option key={jid(w)} value={jid(w)}>{w.label}</option> }}</select></label><Button variant="outline" onClick={connect_points}>Add unverified connection</Button></CardContent></Card>
                    </CardContent>
                </Card>
                <aside className="flex flex-col gap-5">
                    <Card className="shadow-sm"><CardHeader><CardTitle>Graph validation</CardTitle><CardDescription>Calculated from saved floor and graph records.</CardDescription></CardHeader><CardContent className="flex flex-col gap-2"><p className="text-sm font-medium">{graph_summary["message"] as str}</p><p className="text-xs text-muted-foreground">Verified paths are active. Experimental proposals require owner approval and retain experimental provenance.</p><p className="text-xs text-muted-foreground">{str(graph_summary["verified_edges"] as int)} verified · {str(graph_summary["unverified_edges"] as int)} unverified edges</p><Button variant="outline" disabled={True} onClick={approve_proposals}>Approve existing experimental proposals</Button><p className="text-xs text-muted-foreground">Approval is unavailable until this map has owner authorization and saved, aligned corridor proposals. No proposal geometry is generated automatically.</p>{feedback and <p role="status" className="rounded-md bg-muted p-3 text-sm">{feedback}</p>}</CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Selected room</CardTitle><CardDescription>Original names remain unchanged; displayed dimensions are estimates.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3">{for room in rooms { if jid(room) == selected_room_id { <div key={jid(room)} className="flex flex-col gap-3"><p className="rounded-md bg-muted p-3 text-sm">Room {room.room_number}: {room.original_name}</p><label className="flex flex-col gap-1 text-sm">Display label<Input value={label_text} onChange={update_label} /></label><div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1 text-sm">Length (m)<Input type="number" min="0.2" max="200" step="0.1" value={length_text} onChange={update_length} /></label><label className="flex flex-col gap-1 text-sm">Width (m)<Input type="number" min="0.2" max="200" step="0.1" value={width_text} onChange={update_width} /></label></div><p className="text-xs text-muted-foreground">Editing reference dimensions does not resize the schematic block.</p></div> } }}</CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Room checkpoints</CardTitle><CardDescription>All unconfirmed doorways remain pending.</CardDescription></CardHeader><CardContent className="max-h-96 overflow-auto p-0">{for cp in checkpoints { <button key={jid(cp)} onClick={lambda { select_room(cp.room_id); }} className="flex w-full items-center justify-between gap-2 border-b px-4 py-3 text-left hover:bg-muted/50"><span className="text-sm font-medium">Room {cp.room_number}</span><Badge variant="outline">{cp.placement_status}</Badge></button> }}</CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Reference calibration</CardTitle><CardDescription>Single-reference estimate only; schematic distortion remains possible.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1 text-sm">Known metres<Input type="number" value={known_distance} onChange={update_known} /></label><label className="flex flex-col gap-1 text-sm">Pixels<Input type="number" value={pixel_distance} onChange={update_pixels} /></label></div><Button variant="outline" onClick={calibrate}>Update reference scale</Button><p className="text-xs text-muted-foreground">{str(floor.calibration_m_per_px if floor else 0.0909)} m/px estimated, unverified</p></CardContent></Card>
                    <Card className="shadow-sm"><CardHeader><CardTitle>Connections</CardTitle><CardDescription>Approve only after checking the actual floor image.</CardDescription></CardHeader><CardContent className="flex flex-col gap-2">{for edge_record in connections { <div key={jid(edge_record)} className="flex items-center justify-between gap-2 rounded-md border p-2"><span className="text-xs">{edge_record.from_id} → {edge_record.to_id} · {edge_record.verification_status}{" · experimental proposal" if edge_record.provenance == "EXPERIMENTAL_PROPOSAL" else ""}{" · blocked" if edge_record.blocked else ""}</span><Button size="sm" variant="outline" onClick={lambda { verify_edge(jid(edge_record), edge_record.verification_status == "Verified"); }}>{"Mark unverified" if edge_record.verification_status == "Verified" else "Verify connection"}</Button></div> }}</CardContent></Card>
                </aside>
            </div>
            <div className="flex flex-wrap justify-between gap-3 border-t pt-4 text-xs text-muted-foreground"><span>No automatic corridor inference or door placement is active. Anonymous editing has no authentication protection yet.</span><Link to="/" className="font-medium text-primary">Return to public directory</Link></div>
        </main>
    </div>;
}
