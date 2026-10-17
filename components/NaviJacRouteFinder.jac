import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.badge { Badge }
import from .ui.input { Input }
import from .NaviJacThemeToggle { NaviJacThemeToggle }
import from .NaviJacFloorMap { NaviJacFloorMap }
import from "@jac/runtime" { Link }
sv import from ..services.naviJacService { NaviJacFloor, NaviJacRoom, NaviJacCheckpoint, NaviJacWaypoint, NaviJacConnection, seed_sumanadasa_floor, get_floor_editor_data, find_verified_route }

def:pub NaviJacRouteFinder() -> JsxElement {
    has floor_id: str = "",
        floor: NaviJacFloor | None = None,
        rooms: list[NaviJacRoom] = [],
        checkpoints: list[NaviJacCheckpoint] = [],
        waypoints: list[NaviJacWaypoint] = [],
        connections: list[NaviJacConnection] = [],
        start_id: str = "",
        destination_id: str = "",
        search_text: str = "",
        route_points: list[str] = [],
        route_message: str = "Choose a destination. Only verified connections are considered.",
        route_cost: float = 0.0,
        experimental_mode: bool = False,
        location_label: str = "",
        location_source: str = "UNKNOWN",
        gps_message: str = "",
        gps_latitude: str = "",
        gps_longitude: str = "",
        selected_location_id: str = "",
        pending_location_id: str = "",
        loading: bool = True;

    async can with entry {
        floor_id = await seed_sumanadasa_floor();
        data = await get_floor_editor_data(floor_id);
        floor = data["floor"] as NaviJacFloor;
        rooms = data["rooms"] as list[NaviJacRoom];
        checkpoints = data["checkpoints"] as list[NaviJacCheckpoint];
        waypoints = data["waypoints"] as list[NaviJacWaypoint];
        connections = data["connections"] as list[NaviJacConnection];
        loading = False;
    }

    def update_search(e: ChangeEvent) { search_text = e.target.value; }
    def toggle_experimental(e: ChangeEvent) { experimental_mode = e.target.checked; }
    def choose_start(checkpoint_id: str) { pending_location_id = checkpoint_id; }
    def confirm_location() {
        if len(pending_location_id) == 0 { return; }
        start_id = pending_location_id;
        selected_location_id = pending_location_id;
        location_source = "MANUAL_CONFIRMED";
        for cp in checkpoints { if jid(cp) == pending_location_id { location_label = "Room " + str(cp.room_number) + " checkpoint"; } }
        for w in waypoints { if jid(w) == pending_location_id { location_label = w.label; } }
        gps_message = "Manually confirmed on this floor plan.";
    }
    def request_gps() { gps_message = "Phone GPS can estimate your outdoor position, but this floor plan has no verified alignment to geographic coordinates. Choose your indoor checkpoint manually."; location_source = "GPS_APPROXIMATE"; }
    async def choose_destination(room_id: str) -> None {
        destination_id = room_id;
        target_id = "";
        for cp in checkpoints { if cp.room_id == room_id and cp.coordinate_set { target_id = jid(cp); } }
        if len(target_id) == 0 { route_points = []; route_message = "This room entrance is pending placement and verification."; return; }
        if len(start_id) == 0 { route_points = []; route_message = "Choose a placed start checkpoint first."; return; }
        result = await find_verified_route(floor_id, start_id, target_id, experimental_mode);
        route_points = result["waypoints"] as list[str];
        route_message = result["message"] as str;
        route_cost = result["cost"] as float if result["status"] == "ready" else 0.0;
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background"><div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-5 py-4"><Link to="/" className="font-semibold text-foreground">NaviJac</Link><div className="flex items-center gap-3"><Badge variant="outline">Verified connections only</Badge><NaviJacThemeToggle /></div></div></header>
        <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-5 py-6 sm:px-8">
            <section><h1 className="text-2xl font-semibold tracking-tight">Find a room</h1><p className="mt-1 text-sm text-muted-foreground">{floor.building_name if floor else "Sumanadasa Building"} · {floor.floor_name if floor else "Ground Floor"}</p></section>
            <div className="rounded-lg border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950"><p>Route guidance is experimental. No live indoor tracking is available.</p><label className="mt-3 flex items-center gap-2"><input type="checkbox" checked={experimental_mode} onChange={toggle_experimental} />Allow administrator-approved experimental proposals</label><p className="mt-1 text-xs">Verified-only routing remains the default. Experimental paths are approximate and are not physically verified.</p></div>
            <Card className="shadow-sm"><CardHeader><CardTitle>Your indoor position</CardTitle><CardDescription>Confirm a checkpoint on the building map. GPS cannot identify an indoor room.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><label className="flex flex-col gap-1 text-sm font-medium">I'm currently at this location<select className="h-10 rounded-md border bg-background px-3" value={pending_location_id} onChange={lambda (e: ChangeEvent) { choose_start(e.target.value); }}><option value="">Choose a placed checkpoint</option>{for cp in checkpoints { if cp.coordinate_set { <option key={jid(cp)} value={jid(cp)}>Room {cp.room_number} checkpoint</option> } }}{for w in waypoints { <option key={jid(w)} value={jid(w)}>{w.label}</option> }}</select></label><div className="flex flex-wrap gap-2"><Button onClick={lambda { confirm_location(); }}>Confirm my location</Button><Button variant="outline" onClick={lambda { request_gps(); }}>Use phone GPS (approximate)</Button></div>{if len(location_label) > 0 { <div className="rounded-md border bg-background p-3"><p className="font-medium"><span className="mr-2 inline-block h-3 w-3 animate-pulse rounded-full bg-blue-600" />You are here: {location_label}</p><p className="mt-1 text-xs text-muted-foreground">{location_source} · manually confirmed on the floor plan</p><Button variant="ghost" className="mt-2" onClick={lambda { pending_location_id = selected_location_id; }}>Center map on me</Button></div> }}{if len(gps_message) > 0 { <p className="rounded-md bg-muted p-3 text-sm" role="status">{gps_message}</p> }}</CardContent></Card>
            <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_20rem]">
                <NaviJacFloorMap />
                 <Card className="shadow-sm"><CardHeader><CardTitle>Floor map</CardTitle><CardDescription>Routes require walkable connections confirmed from the source drawing.</CardDescription></CardHeader><CardContent><div className="flex min-h-80 flex-col items-center justify-center gap-3 rounded-lg border border-dashed bg-background p-6 text-center"><p className="font-medium">{route_message}</p>{if len(route_points) > 0 { <p className="text-sm text-muted-foreground">{str(len(route_points))} checkpoints · cost {str(route_cost)} administrator-defined map units</p> }}<p className="text-xs text-muted-foreground">The image-supported plan is shown above. No graph entrances or connected route have been added until doorway geometry is mapped; this reconstruction does not establish a walkable route.</p></div></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>Destination search</CardTitle><CardDescription>Search by supplied room number or room name.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><Input value={search_text} onChange={update_search} placeholder="Search room name or number" /><label className="flex flex-col gap-1 text-sm font-medium">Starting checkpoint<select className="h-10 rounded-md border bg-background px-3" value={start_id} onChange={lambda (e: ChangeEvent) { choose_start(e.target.value); }}><option value="">Select placed start</option>{for cp in checkpoints { if cp.coordinate_set { <option key={jid(cp)} value={jid(cp)}>Room {cp.room_number} checkpoint</option> } }}{for w in waypoints { <option key={jid(w)} value={jid(w)}>{w.label}</option> }}</select></label>{if loading { <p className="text-sm text-muted-foreground">Loading room directory…</p> }}{for room in rooms { if len(search_text.strip()) == 0 or search_text.lower() in room.original_name.lower() or search_text in str(room.room_number) { <Button key={jid(room)} variant="outline" className="justify-start" onClick={lambda { choose_destination(jid(room)); }}>Room {room.room_number} · {room.display_label}</Button> } }}</CardContent></Card>
            </div>
            {for selected_room in rooms { if jid(selected_room) == destination_id { <Card className="shadow-sm"><CardHeader><CardTitle>Room {selected_room.room_number} · {selected_room.display_label}</CardTitle><CardDescription>{selected_room.original_name}</CardDescription></CardHeader><CardContent className="flex flex-col gap-2"><p className="text-sm">Category: {selected_room.category}</p><p className="text-sm text-muted-foreground">Estimated dimensions: {str(selected_room.length_m)} × {str(selected_room.width_m)} m ({selected_room.measurement_status})</p>{selected_room.description and <p className="text-sm">{selected_room.description}</p>}{selected_room.notes and <p className="text-sm text-muted-foreground">{selected_room.notes}</p>}<p className="rounded-md bg-muted p-3 text-sm">{route_message}</p></CardContent></Card> } }}
            <div className="flex justify-between border-t pt-4 text-sm"><Link to="/" className="text-primary">Directory</Link><Link to="/maps/sumanadasa/first-floor/edit" className="text-primary">Map editor</Link></div>
        </main>
    </div>;
}
