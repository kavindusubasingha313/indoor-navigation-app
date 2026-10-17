import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.input { Input }
import from .ui.badge { Badge }
import from "@jac/runtime" { Link }
sv import from ..services.naviJacService { NaviJacFloor, NaviJacRoom, NaviJacGeometry, seed_sumanadasa_floor, get_floor_editor_data, save_floor_editor_changes, calibrate_floor_scale }

def:pub NaviJacFloorEditor() -> JsxElement {
    has floor_id: str = "",
        floor: NaviJacFloor | None = None,
        rooms: list[NaviJacRoom] = [],
        geometry: list[NaviJacGeometry] = [],
        selected_id: str = "",
        length_text: str = "14.0",
        width_text: str = "6.4",
        label_text: str = "Electrical Engineering seminar room",
        tool: str = "select",
        feedback: str = "",
        saving: bool = False,
        show_image: bool = True,
        show_geometry: bool = True,
        show_labels: bool = True,
        show_navigation: bool = True,
        known_distance: str = "14",
        pixel_distance: str = "154";

    async can with entry {
        floor = await seed_sumanadasa_floor();
        floor_id = jid(floor);
        result = await get_floor_editor_data(floor_id);
        floor = result["floor"] as NaviJacFloor;
        rooms = result["rooms"] as list[NaviJacRoom];
        geometry = result["geometry"] as list[NaviJacGeometry];
        if len(rooms) > 0 {
            selected_id = jid(rooms[0]);
            length_text = str(rooms[0].length_m);
            width_text = str(rooms[0].width_m);
            label_text = rooms[0].display_label;
        }
    }

    def select_room(room_id: str) {
        selected_id = room_id;
        for r in rooms {
            if jid(r) == room_id {
                length_text = str(r.length_m);
                width_text = str(r.width_m);
                label_text = r.display_label;
            }
        }
    }
    def update_length(e: ChangeEvent) { length_text = e.target.value; }
    def update_width(e: ChangeEvent) { width_text = e.target.value; }
    def update_label(e: ChangeEvent) { label_text = e.target.value; }
    def update_known(e: ChangeEvent) { known_distance = e.target.value; }
    def update_pixels(e: ChangeEvent) { pixel_distance = e.target.value; }
    def choose_tool(next_tool: str) { tool = next_tool; }
    def toggle_image(e: ChangeEvent) { show_image = e.target.checked; }
    def toggle_geometry(e: ChangeEvent) { show_geometry = e.target.checked; }
    def toggle_labels(e: ChangeEvent) { show_labels = e.target.checked; }
    def toggle_navigation(e: ChangeEvent) { show_navigation = e.target.checked; }

    async def save_selected -> None {
        if len(selected_id) == 0 { feedback = "Select a room before saving."; return; }
        saving = True;
        result = await save_floor_editor_changes(floor_id, selected_id, float(length_text), float(width_text), 10.0, 10.0, label_text, "", 0.0, 0.0, 0.0, 0.0);
        feedback = result["message"] as str;
        data = await get_floor_editor_data(floor_id);
        rooms = data["rooms"] as list[NaviJacRoom];
        saving = False;
    }

    async def add_geometry(kind: str) -> None {
        result = await save_floor_editor_changes(floor_id, selected_id, float(length_text), float(width_text), 10.0, 10.0, label_text, kind, 15.0, 20.0, 85.0, 80.0);
        feedback = result["message"] as str;
        data = await get_floor_editor_data(floor_id);
        geometry = data["geometry"] as list[NaviJacGeometry];
    }

    async def calibrate -> None {
        result = await calibrate_floor_scale(floor_id, float(known_distance), float(pixel_distance));
        feedback = result["message"] as str;
        data = await get_floor_editor_data(floor_id);
        floor = data["floor"] as NaviJacFloor;
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur">
            <div className="mx-auto flex max-w-[1600px] flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6">
                <div className="flex items-center gap-3"><Link to="/" className="text-sm text-muted-foreground hover:text-foreground">NaviJac</Link><span className="text-muted-foreground">/</span><span className="font-semibold">First-floor editor</span></div>
                <Badge variant="outline">Experimental workspace</Badge>
            </div>
        </header>
        <main className="mx-auto flex w-full max-w-[1600px] flex-col gap-5 px-4 py-5 sm:px-6">
            <section className="flex flex-wrap items-end justify-between gap-4">
                <div className="flex flex-col gap-1"><h1 className="text-2xl font-semibold tracking-tight">{floor.building_name if floor else "Sumanadasa Building"} · {floor.floor_name if floor else "First Floor"}</h1><p className="text-sm text-muted-foreground">Electrical Engineering · University of Moratuwa</p></div>
                <Button onClick={save_selected} disabled={saving}>{"Save room changes" if not saving else "Saving…"}</Button>
            </section>
            <div className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950">
                <p className="font-semibold">Estimated reference plan, not verified architectural measurements</p>
                <p className="mt-1">Room 1’s 14 m horizontal span is calibrated against approximately 154 px in the supplied schematic (about 0.0909 m/px). This single reference does not prove uniform scale. Verify dimensions, walls, doors, stairs, and walkable paths before real-world use. Not for construction, accessibility clearance, or accurate travel-time estimates.</p>
            </div>
            <div className="grid min-w-0 gap-5 xl:grid-cols-[minmax(0,1fr)_22rem]">
                <Card className="min-w-0 shadow-sm">
                    <CardHeader className="flex flex-wrap items-start justify-between gap-3">
                        <div><CardTitle>Floor sketch</CardTitle><CardDescription>Illustrative room blocks use normalized coordinates; imported source-image alignment is not available in this session.</CardDescription></div>
                        <div className="flex flex-wrap gap-2">
                            <Button variant={"default" if tool == "select" else "outline"} size="sm" onClick={lambda { choose_tool("select"); }}>Select</Button>
                            <Button variant={"default" if tool == "wall" else "outline"} size="sm" onClick={lambda { choose_tool("wall"); }}>Wall</Button>
                            <Button variant="outline" size="sm" onClick={lambda { add_geometry("wall"); }}>Add wall</Button>
                            <Button variant="outline" size="sm" onClick={lambda { add_geometry("waypoint"); }}>Add waypoint</Button>
                        </div>
                    </CardHeader>
                    <CardContent className="flex flex-col gap-3">
                        <div className="flex flex-wrap gap-4 rounded-lg border bg-muted/30 p-3 text-sm">
                            <label className="flex items-center gap-2"><input type="checkbox" checked={show_image} onChange={toggle_image} />Source image</label>
                            <label className="flex items-center gap-2"><input type="checkbox" checked={show_geometry} onChange={toggle_geometry} />Walls / room blocks</label>
                            <label className="flex items-center gap-2"><input type="checkbox" checked={show_labels} onChange={toggle_labels} />Room labels</label>
                            <label className="flex items-center gap-2"><input type="checkbox" checked={show_navigation} onChange={toggle_navigation} />Navigation overlay</label>
                        </div>
                        <div className="overflow-auto rounded-lg border bg-background p-2">
                            <svg viewBox="0 0 1000 480" className="block h-auto min-h-[320px] w-full" role="img" aria-label="Estimated room layout sketch">
                                {if show_image and floor and floor.original_map_id {
                                    <text x="20" y="24" fill="currentColor" fontSize="14">Original floor-plan image linked to building record</text>
                                }}
                                {if show_geometry {
                                    <rect x="20" y="45" width="960" height="390" rx="10" fill="none" stroke="currentColor" strokeWidth="3" />
                                    for (index, room) in enumerate(rooms) {
                                        <g key={jid(room)} onClick={lambda { select_room(jid(room)); }} className="cursor-pointer">
                                            <rect x={str(30 + (index % 7) * 134)} y={str(65 + (index / 7) * 115)} width="120" height="92" rx="6" fill={"#ede9fe" if jid(room) == selected_id else "#f5f5f4"} stroke={"#6d28d9" if jid(room) == selected_id else "#a8a29e"} strokeWidth="2" />
                                            {if show_labels { <text x={str(38 + (index % 7) * 134)} y={str(88 + (index / 7) * 115)} fontSize="12" fill="#292524">{"#" + str(room.room_number)}</text> }}
                                            {if show_labels { <text x={str(38 + (index % 7) * 134)} y={str(108 + (index / 7) * 115)} fontSize="10" fill="#44403c">{room.display_label}</text> }}
                                        </g>
                                    }}
                                }}
                                {if show_geometry and show_navigation {
                                    for item in geometry {
                                        if item.geometry_kind == "wall" {
                                            <line key={jid(item)} x1={str(item.x1 * 9.6 + 20)} y1={str(item.y1 * 3.9 + 45)} x2={str(item.x2 * 9.6 + 20)} y2={str(item.y2 * 3.9 + 45)} stroke="#7c3aed" strokeWidth="5" />
                                        } else {
                                            <circle key={jid(item)} cx={str(item.x1 * 9.6 + 20)} cy={str(item.y1 * 3.9 + 45)} r="8" fill="#0f766e" />
                                        }
                                    }
                                }}
                            </svg>
                        </div>
                        <p className="text-xs text-muted-foreground">Tool selected: {tool}. Current experimental controls add a sample wall or waypoint; positions and connections require manual verification. No doors or routes are inferred from room adjacency.</p>
                    </CardContent>
                </Card>
                <aside className="flex flex-col gap-5">
                    <Card className="shadow-sm">
                        <CardHeader><CardTitle>Selected room</CardTitle><CardDescription>Values remain estimates. Original room names are preserved.</CardDescription></CardHeader>
                        <CardContent className="flex flex-col gap-3">
                            {for room in rooms {
                                if jid(room) == selected_id {
                                    <div key={jid(room)} className="flex flex-col gap-3">
                                        <div className="rounded-md bg-muted/50 p-3"><p className="text-xs text-muted-foreground">Room {room.room_number} · {room.measurement_status}</p><p className="font-medium">{room.original_name}</p><p className="text-xs text-muted-foreground">Estimated area: {str(round(room.length_m * room.width_m, 1))} m²</p>{room.notes and <p className="mt-1 text-xs text-amber-800">{room.notes}</p>}</div>
                                        <label className="flex flex-col gap-1 text-sm font-medium">Display label<Input value={label_text} onChange={update_label} /></label>
                                        <div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1 text-sm font-medium">Length (m)<Input type="number" min="0.2" max="200" step="0.1" value={length_text} onChange={update_length} /></label><label className="flex flex-col gap-1 text-sm font-medium">Width (m)<Input type="number" min="0.2" max="200" step="0.1" value={width_text} onChange={update_width} /></label></div>
                                        <p className="text-xs text-muted-foreground">Changing these reference values does not resize the schematic room block.</p>
                                    </div>
                                }
                            }}
                            {if len(rooms) == 0 { <p className="text-sm text-muted-foreground">Room estimates are not available yet. Reload the editor to retry seed data.</p> }}
                            {feedback and <p role="status" className="rounded-md bg-muted p-3 text-sm">{feedback}</p>}
                        </CardContent>
                    </Card>
                    <Card className="shadow-sm">
                        <CardHeader><CardTitle>Scale calibration</CardTitle><CardDescription>Choose two points and enter their known span in metres.</CardDescription></CardHeader>
                        <CardContent className="flex flex-col gap-3">
                            <p className="text-xs text-amber-800">One-point calibration cannot correct image distortion or inconsistent schematic scale.</p>
                            <div className="grid grid-cols-2 gap-3"><label className="flex flex-col gap-1 text-sm">Known distance (m)<Input type="number" min="0.1" step="0.1" value={known_distance} onChange={update_known} /></label><label className="flex flex-col gap-1 text-sm">Pixel distance<Input type="number" min="1" step="1" value={pixel_distance} onChange={update_pixels} /></label></div>
                            <Button variant="outline" onClick={calibrate}>Apply calibration estimate</Button>
                            <p className="text-xs text-muted-foreground">Current reference: {str(floor.calibration_m_per_px if floor else 0.0909)} m/px · Unverified estimate</p>
                        </CardContent>
                    </Card>
                    <Card className="shadow-sm">
                        <CardHeader><CardTitle>Numbered room list</CardTitle><CardDescription>Names and dimensions transcribed from the supplied estimate table.</CardDescription></CardHeader>
                        <CardContent className="max-h-80 overflow-auto p-0">
                            {for room in rooms {
                                <button key={jid(room)} onClick={lambda { select_room(jid(room)); }} className={"flex w-full items-start justify-between gap-3 border-b px-4 py-3 text-left transition-colors hover:bg-muted/50 " + ("bg-primary/10" if jid(room) == selected_id else "")}>
                                    <span className="min-w-0"><span className="block text-xs text-muted-foreground">Room {room.room_number}</span><span className="block text-sm font-medium">{room.display_label}</span></span>
                                    <span className="shrink-0 text-right text-xs tabular-nums text-muted-foreground">{str(room.length_m)} × {str(room.width_m)} m</span>
                                </button>
                            }}
                        </CardContent>
                    </Card>
                </aside>
            </div>
            <div className="flex flex-wrap items-center justify-between gap-3 border-t pt-4 text-xs text-muted-foreground"><span>Editor permissions are not enabled yet. Do not publish unverified geometry as official building data.</span><Link to="/" className="font-medium text-primary">Return to public directory</Link></div>
        </main>
    </div>;
}
