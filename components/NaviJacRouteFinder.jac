import from .ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }
import from .ui.button { Button }
import from .ui.badge { Badge }
import from .ui.input { Input }
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
    def choose_start(checkpoint_id: str) { start_id = checkpoint_id; }
    async def choose_destination(room_id: str) -> None {
        destination_id = room_id;
        target_id = "";
        for cp in checkpoints { if cp.room_id == room_id and cp.coordinate_set { target_id = jid(cp); } }
        if len(target_id) == 0 { route_points = []; route_message = "This room entrance is pending placement and verification."; return; }
        if len(start_id) == 0 { route_points = []; route_message = "Choose a placed start checkpoint first."; return; }
        result = await find_verified_route(floor_id, start_id, target_id);
        route_points = result["waypoints"] as list[str];
        route_message = result["message"] as str;
        route_cost = result["cost"] as float if result["status"] == "ready" else 0.0;
    }

    return <div className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background"><div className="mx-auto flex max-w-6xl items-center justify-between gap-3 px-5 py-4"><Link to="/" className="font-semibold text-foreground">NaviJac</Link><Badge variant="outline">Verified connections only</Badge></div></header>
        <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-5 py-6 sm:px-8">
            <section><h1 className="text-2xl font-semibold tracking-tight">Find a room</h1><p className="mt-1 text-sm text-muted-foreground">{floor.building_name if floor else "Sumanadasa Building"} · {floor.floor_name if floor else "First Floor"}</p></section>
            <div className="rounded-lg border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950">Route guidance is experimental. Unknown entrances and unverified links are never treated as walkable. No live indoor tracking is available.</div>
            <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_20rem]">
                <Card className="shadow-sm"><CardHeader><CardTitle>Floor map</CardTitle><CardDescription>Route path appears only when every traversed connection is verified.</CardDescription></CardHeader><CardContent><div className="flex min-h-80 flex-col items-center justify-center gap-3 rounded-lg border border-dashed bg-background p-6 text-center"><p className="font-medium">{route_message}</p>{if len(route_points) > 0 { <p className="text-sm text-muted-foreground">{str(len(route_points))} checkpoints · cost {str(route_cost)} administrator-defined map units</p> }}<p className="text-xs text-muted-foreground">The uploaded source image has not been attached to the editor coordinate system yet, so no route overlay is drawn on that image.</p></div></CardContent></Card>
                <Card className="shadow-sm"><CardHeader><CardTitle>Destination search</CardTitle><CardDescription>Search by supplied room number or room name.</CardDescription></CardHeader><CardContent className="flex flex-col gap-3"><Input value={search_text} onChange={update_search} placeholder="Search room name or number" /><label className="flex flex-col gap-1 text-sm font-medium">Starting checkpoint<select className="h-10 rounded-md border bg-background px-3" value={start_id} onChange={lambda (e: ChangeEvent) { choose_start(e.target.value); }}><option value="">Select placed start</option>{for cp in checkpoints { if cp.coordinate_set { <option key={jid(cp)} value={jid(cp)}>Room {cp.room_number} checkpoint</option> } }}{for w in waypoints { <option key={jid(w)} value={jid(w)}>{w.label}</option> }}</select></label>{if loading { <p className="text-sm text-muted-foreground">Loading room directory…</p> }}{for room in rooms { if len(search_text.strip()) == 0 or search_text.lower() in room.original_name.lower() or search_text in str(room.room_number) { <Button key={jid(room)} variant="outline" className="justify-start" onClick={lambda { choose_destination(jid(room)); }}>Room {room.room_number} · {room.display_label}</Button> } }}</CardContent></Card>
            </div>
            <div className="flex justify-between border-t pt-4 text-sm"><Link to="/" className="text-primary">Directory</Link><Link to="/maps/sumanadasa/first-floor/edit" className="text-primary">Map editor</Link></div>
        </main>
    </div>;
}
