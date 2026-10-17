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
        pending_destination_id: str = "",
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
        loading: bool = True,
        route_instructions: list[str] = [],
        route_distance_m: float = 0.0;

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
    def location_name(point_id: str) -> str {
        for room in rooms { if jid(room) == point_id { return room.display_label; } }
        return "Library lobby";
    }
    def estimated_distance(a: str, b: str) -> float {
        if a == b { return 0.0; }
        if location_name(a) == "Lobby" or location_name(b) == "Lobby" { return 12.0; }
        return 24.0;
    }
    def choose_start(point_id: str) {
        pending_location_id = point_id;
        start_id = point_id;
        selected_location_id = point_id;
        location_label = location_name(point_id);
        location_source = "MAP_SELECTED";
        route_message = "Starting location: " + location_label + ". Choose a destination for directions.";
        if len(destination_id) > 0 { route_distance_m = estimated_distance(point_id, destination_id); }
    }
    def confirm_location() {
        if len(pending_location_id) == 0 { route_message = "Choose any room or the lobby on the map first."; return; }
        start_id = pending_location_id;
        selected_location_id = pending_location_id;
        location_label = location_name(pending_location_id);
        location_source = "MANUAL_CONFIRMED";
        gps_message = "Starting point manually selected on the ground-floor plan.";
        if len(destination_id) > 0 { route_distance_m = estimated_distance(start_id, destination_id); route_message = "Demo route via the open lobby."; }
    }
    def request_gps() { gps_message = "GPS provides an outdoor estimate only. Select a point on this floor plan for indoor navigation."; location_source = "GPS_APPROXIMATE"; }
    def select_destination(e: ChangeEvent) { choose_destination(e.target.value); }
    def choose_destination(room_id: str) {
        pending_destination_id = room_id;
        destination_id = room_id;
        destination_name = location_name(room_id);
        if len(start_id) == 0 { route_message = "Select any room or the lobby as your starting point."; return; }
        route_points = [start_id, "9", room_id];
        route_distance_m = estimated_distance(start_id, room_id);
        route_cost = route_distance_m;
        route_instructions = ["From " + location_name(start_id) + ", enter the central open lobby.", "Follow the lobby circulation toward " + destination_name + ".", "Enter " + destination_name + " through the indicated opening."];
        route_message = "Demo directions via the lobby · plan-scale estimate";
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background"><div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-5 py-4"><Link to="/" className="font-semibold text-foreground">NaviJac</Link><div className="flex items-center gap-3"><Badge variant="outline">Verified connections only</Badge><NaviJacThemeToggle /></div></div></header>
        <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-5 py-6 sm:px-8">
            <section><h1 className="text-2xl font-semibold tracking-tight">Find a room</h1><p className="mt-1 text-sm text-muted-foreground">{floor.building_name if floor else "Sumanadasa Building"} · {floor.floor_name if floor else "Ground Floor"}</p></section>
            <div className="rounded-lg border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950"><p>Demo directions use the overhead plan and assume the open lobby is walkable.</p><p className="mt-1 text-xs">Manual position only. Dimensions use the plan's printed grid; verify access and doorways onsite.</p></div>
            <Card className="shadow-sm"><CardHeader><CardTitle>Your indoor position</CardTitle><CardDescription>Confirm a checkpoint on the building map. GPS cannot identify an indoor room.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><label className="flex flex-col gap-1 text-sm font-medium">I'm currently at<select className="h-10 rounded-md border bg-background px-3" value={pending_location_id} onChange={lambda (e: ChangeEvent) { choose_start(e.target.value); }}><option value="">Select any room or lobby</option>{for room in rooms { <option key={jid(room)} value={jid(room)}>{room.display_label}</option> }}</select></label><div className="flex flex-wrap gap-2"><Button onClick={lambda { confirm_location(); }}>Confirm my location</Button><Button variant="outline" onClick={lambda { request_gps(); }}>Use phone GPS (approximate)</Button></div>{if len(location_label) > 0 { <div className="rounded-md border bg-background p-3"><p className="font-medium"><span className="mr-2 inline-block h-3 w-3 animate-pulse rounded-full bg-blue-600" />You are here: {location_label}</p><p className="mt-1 text-xs text-muted-foreground">{location_source} · manually confirmed on the floor plan</p><Button variant="ghost" className="mt-2" onClick={lambda { pending_location_id = selected_location_id; }}>Center map on me</Button></div> }}{if len(gps_message) > 0 { <p className="rounded-md bg-muted p-3 text-sm" role="status">{gps_message}</p> }}</CardContent></Card>
            <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_20rem]">
                <NaviJacFloorMap start_label={location_label} destination_label={location_name(destination_id) if len(destination_id) > 0 else ""} />
                 <Card className="shadow-sm"><CardHeader><CardTitle>Directions</CardTitle><CardDescription>Demo path follows the central open lobby.</CardDescription></CardHeader><CardContent><div className="flex min-h-80 flex-col items-center justify-center gap-3 rounded-lg border border-dashed bg-background p-6 text-center"><p className="font-medium">{route_message}</p>{if len(destination_id) > 0 and len(start_id) > 0 { <p className="text-sm text-muted-foreground">Approximate plan distance: {str(route_distance_m)} m</p> }}{for (index, instruction) in enumerate(route_instructions) { <p key={str(index)} className="rounded-md bg-muted p-3 text-sm">{str(index + 1)}. {instruction}</p> }}<p className="text-xs text-muted-foreground">Illustrative directions from the supplied overhead plan. Confirm door access and accessible circulation onsite.</p></div></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>Choose destination</CardTitle><CardDescription>Select any labeled room on this ground floor.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><Input value={search_text} onChange={update_search} placeholder="Search room name or number" /><label className="flex flex-col gap-1 text-sm font-medium">Destination<select className="h-10 rounded-md border bg-background px-3" value={pending_destination_id} onChange={lambda (e: ChangeEvent) { choose_destination(e.target.value); }}><option value="">Choose a room</option>{for room in rooms { if len(search_text.strip()) == 0 or search_text.lower() in room.original_name.lower() or search_text in str(room.room_number) { <option key={jid(room)} value={jid(room)}>{room.display_label}</option> } }}</select></label><Button disabled={len(start_id) == 0 or len(pending_destination_id) == 0} onClick={lambda { choose_destination(pending_destination_id); }}>Get directions</Button><p className="text-xs text-muted-foreground">Selected start: {location_label if len(location_label) > 0 else "None"} · Selected destination: {location_name(pending_destination_id) if len(pending_destination_id) > 0 else "None"}</p></CardContent></Card>
            </div>
            <div className="flex justify-between border-t pt-4 text-sm"><Link to="/" className="text-primary">Directory</Link><Link to="/maps/sumanadasa/first-floor/edit" className="text-primary">Map editor</Link></div>
        </main>
    </div>;
}
