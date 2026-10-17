enum NaviJacRole {
    ADMINISTRATOR = "administrator",
    MAP_CREATOR = "map_creator",
    PUBLIC_VIEWER = "public_viewer"
}

enum NaviJacCheckpointType: str {
    ROOM_ENTRANCE = "ROOM_ENTRANCE",
    BUILDING_ENTRANCE = "BUILDING_ENTRANCE",
    CORRIDOR_JUNCTION = "CORRIDOR_JUNCTION",
    STAIRCASE = "STAIRCASE",
    LIFT = "LIFT",
    QR_LOCATION = "QR_LOCATION",
    DESTINATION = "DESTINATION"
}

node NaviJacAccount { has display_name: str, role: NaviJacRole, email: str = ""; }

node NaviJacMap {
    has name: str,
        description: str = "",
        is_public: bool = True,
        floor_count: int = 1,
        floor_plan_data: str = "",
        floor_plan_type: str = "";
}

node NaviJacFloor {
    has building_name: str,
        department: str = "",
        university: str = "",
        floor_name: str = "",
        level_number: int = 1,
        calibration_m_per_px: float = 0.0909,
        calibration_note: str = "Room 1 horizontal length: 14 m over approximately 154 px; source illustration only.",
        distortion_warning: str = "Estimated dimensions follow schematic image proportions and are not independently verified.",
        original_map_id: str = "";
}

node NaviJacRoom {
    has floor_id: str,
        room_number: int,
        original_name: str,
        length_m: float,
        width_m: float,
        measurement_status: str = "Estimated, unverified",
        category: str = "Unspecified",
        description: str = "",
        notes: str = "",
        x: float = 0.0,
        y: float = 0.0,
        display_label: str = "";
}

node NaviJacGeometry {
    has floor_id: str,
        geometry_kind: str,
        x1: float = 0.0,
        y1: float = 0.0,
        x2: float = 0.0,
        y2: float = 0.0,
        label: str = "";
}

node NaviJacCheckpoint {
    has floor_id: str,
        room_id: str,
        room_number: int,
        checkpoint_type: NaviJacCheckpointType = NaviJacCheckpointType.ROOM_ENTRANCE,
        placement_status: str = "Pending Placement",
        x: float = 0.0,
        y: float = 0.0,
        coordinate_set: bool = False,
        nearest_waypoint_id: str = "",
        qr_url: str = "";
}

node NaviJacWaypoint {
    has floor_id: str,
        label: str = "Corridor point",
        x: float = 0.0,
        y: float = 0.0;
}

node NaviJacConnection {
    has floor_id: str,
        from_id: str,
        to_id: str,
        cost: float = 1.0,
        verification_status: str = "Unverified",
        blocked: bool = False,
        accessible: bool = False;
}

def:pub get_public_maps() -> list[NaviJacMap] { return [root -->][?:NaviJacMap, is_public]; }

def:pub create_public_map(name: str, description: str) -> NaviJacMap | None {
    clean_name = name.strip();
    if len(clean_name) == 0 { return None; }
    return root ++> NaviJacMap(name=clean_name, description=description.strip());
}

def:pub upload_floor_plan(map_id: str, image_data: str, image_type: str) -> NaviJacMap | None {
    if len(image_data) == 0 or len(image_data) > 7000000 { return None; }
    if image_type != "image/png" and image_type != "image/jpeg" { return None; }
    for building in [root -->][?:NaviJacMap, is_public] {
        if jid(building) == map_id { building.floor_plan_data = image_data; building.floor_plan_type = image_type; return building; }
    }
    return None;
}

def:pub seed_sumanadasa_floor() -> str {
    for f in [root -->][?:NaviJacFloor] {
        if f.building_name == "Dr. L. H. Sumanadasa Building" and f.floor_name == "First Floor" {
            floor_key = jid(f); seed_sumanadasa_rooms(floor_key); return floor_key;
        }
    }
    created = root ++> NaviJacFloor(building_name="Dr. L. H. Sumanadasa Building", department="Electrical Engineering", university="University of Moratuwa", floor_name="First Floor");
    floor_key = jid(created); seed_sumanadasa_rooms(floor_key); return floor_key;
}

def seed_sumanadasa_rooms(floor_id: str) {
    names: list[str] = ["Electrical Engineering seminar room", "Senior staff common room", "Department office", "Head of the Department", "Electrical Engineering Board room", "Electrical Measurements Laboratory", "High Voltage Laboratory (Control Room)", "Staff room - Prof. N. Wickramarachchi", "Staff room", "Staff room - Dr. L. Weeramanckara", "Staff room - Prof. W.D.A.S. Rodrigo", "Staff room - Prof. J.P. Karunadasa", "Staff rooms - multiple academic staff", "Final Year Lecture Room", "Robotics and Automation Laboratory (section)", "Staff room - Dr. R.M.M. Ruwanthika", "Robotics and Automation Laboratory (section)", "Electrical Installations Laboratory", "Staff rooms - Contract Lecturers"];
    lengths: list[float] = [14.0, 3.8, 3.9, 6.2, 6.3, 21.5, 9.5, 9.5, 6.5, 6.5, 9.5, 9.5, 9.5, 13.8, 5.9, 6.2, 11.8, 18.4, 7.7];
    widths: list[float] = [6.4, 6.4, 6.4, 6.4, 6.4, 6.4, 6.4, 5.4, 5.5, 5.4, 5.5, 5.4, 8.1, 6.4, 6.4, 6.4, 6.4, 6.4, 6.4];
    for (i, name) in enumerate(names) {
        found = False;
        for r in [root -->][?:NaviJacRoom] { if r.floor_id == floor_id and r.room_number == i + 1 { found = True; } }
        if not found {
            note = "";
            if i + 1 == 8 or i + 1 == 11 { note = "Width uses bounding extent; stepped boundary not represented."; }
            if i + 1 == 13 { note = "Numbered area includes multiple staff rooms; internal partitions not specified."; }
            if i + 1 == 15 or i + 1 == 17 { note = "Section of Robotics and Automation Laboratory; do not assume independent facility."; }
            root ++> NaviJacRoom(floor_id=floor_id, room_number=i + 1, original_name=name, display_label=name, length_m=lengths[i], width_m=widths[i], notes=note);
        }
    }
}

def:pub get_floor_editor_data(floor_id: str) -> dict {
    floor: NaviJacFloor | None = None;
    rooms: list[NaviJacRoom] = [];
    geometry: list[NaviJacGeometry] = [];
    checkpoints: list[NaviJacCheckpoint] = [];
    waypoints: list[NaviJacWaypoint] = [];
    connections: list[NaviJacConnection] = [];
    for f in [root -->][?:NaviJacFloor] { if jid(f) == floor_id { floor = f; } }
    if floor is None { floor_key = seed_sumanadasa_floor(); floor = jobj(floor_key) as NaviJacFloor; }
    fid = jid(floor);
    for r in [root -->][?:NaviJacRoom] { if r.floor_id == fid { rooms = rooms + [r]; } }
    if len(rooms) == 0 { seed_sumanadasa_rooms(fid); for r in [root -->][?:NaviJacRoom] { if r.floor_id == fid { rooms = rooms + [r]; } } }
    for c in [root -->][?:NaviJacCheckpoint] { if c.floor_id == fid { checkpoints = checkpoints + [c]; } }
    for r in rooms {
        has_checkpoint = False;
        for c in checkpoints { if c.room_id == jid(r) { has_checkpoint = True; } }
        if not has_checkpoint { fresh = root ++> NaviJacCheckpoint(floor_id=fid, room_id=jid(r), room_number=r.room_number); checkpoints = checkpoints + [fresh]; }
    }
    for g in [root -->][?:NaviJacGeometry] { if g.floor_id == fid { geometry = geometry + [g]; } }
    for w in [root -->][?:NaviJacWaypoint] { if w.floor_id == fid { waypoints = waypoints + [w]; } }
    for e in [root -->][?:NaviJacConnection] { if e.floor_id == fid { connections = connections + [e]; } }
    return {"floor": floor, "rooms": rooms, "geometry": geometry, "checkpoints": checkpoints, "waypoints": waypoints, "connections": connections};
}

def:pub save_floor_editor_changes(floor_id: str, room_id: str, length_m: float, width_m: float, x: float, y: float, label: str, geometry_kind: str, x1: float, y1: float, x2: float, y2: float) -> dict {
    floor: NaviJacFloor | None = None;
    for f in [root -->][?:NaviJacFloor] { if jid(f) == floor_id { floor = f; } }
    if floor is None { floor_key = seed_sumanadasa_floor(); floor = jobj(floor_key) as NaviJacFloor; }
    if length_m < 0.2 or length_m > 200.0 or width_m < 0.2 or width_m > 200.0 { return {"ok": False, "message": "Dimensions must be between 0.2 m and 200 m."}; }
    for r in [root -->][?:NaviJacRoom] { if jid(r) == room_id and r.floor_id == jid(floor) { r.length_m = length_m; r.width_m = width_m; r.x = x; r.y = y; r.display_label = label; } }
    if geometry_kind == "wall" or geometry_kind == "waypoint" { root ++> NaviJacGeometry(floor_id=jid(floor), geometry_kind=geometry_kind, x1=x1, y1=y1, x2=x2, y2=y2); }
    return {"ok": True, "message": "Floor edits saved. Dimension estimates remain unverified."};
}

def:pub calibrate_floor_scale(floor_id: str, known_distance_m: float, pixel_distance: float) -> dict {
    if known_distance_m <= 0 or pixel_distance <= 0 { return {"ok": False, "message": "Enter positive distances."}; }
    for f in [root -->][?:NaviJacFloor] { if jid(f) == floor_id { f.calibration_m_per_px = known_distance_m / pixel_distance; f.calibration_note = "User calibration from selected points; other dimensions remain estimated and may be distorted."; return {"ok": True, "scale": f.calibration_m_per_px, "message": f.distortion_warning}; } }
    return {"ok": False, "message": "Floor not found."};
}

def:pub save_checkpoint_placement(floor_id: str, room_id: str, x: float, y: float, confirm_entrance: bool) -> NaviJacCheckpoint | None {
    if x < 0 or x > 100 or y < 0 or y > 100 { return None; }
    for r in [root -->][?:NaviJacRoom] {
        if jid(r) == room_id and r.floor_id == floor_id {
            status = "Placed, doorway pending verification";
            if confirm_entrance { status = "Verified entrance"; }
            for c in [root -->][?:NaviJacCheckpoint] { if c.room_id == room_id and c.floor_id == floor_id { c.x = x; c.y = y; c.coordinate_set = True; c.placement_status = status; return c; } }
            return root ++> NaviJacCheckpoint(floor_id=floor_id, room_id=room_id, room_number=r.room_number, x=x, y=y, coordinate_set=True, placement_status=status);
        }
    }
    return None;
}

def:pub save_corridor_waypoint(floor_id: str, label: str, x: float, y: float) -> NaviJacWaypoint | None {
    if x < 0 or x > 100 or y < 0 or y > 100 { return None; }
    return root ++> NaviJacWaypoint(floor_id=floor_id, label=label.strip() if len(label.strip()) > 0 else "Corridor point", x=x, y=y);
}

def:pub save_connection_edge(floor_id: str, from_id: str, to_id: str, cost: float) -> NaviJacConnection | None {
    if from_id == to_id or cost <= 0 { return None; }
    from_exists = False; to_exists = False;
    for w in [root -->][?:NaviJacWaypoint] { if w.floor_id == floor_id and jid(w) == from_id { from_exists = True; } if w.floor_id == floor_id and jid(w) == to_id { to_exists = True; } }
    for c in [root -->][?:NaviJacCheckpoint] { if c.floor_id == floor_id and c.coordinate_set and jid(c) == from_id { from_exists = True; } if c.floor_id == floor_id and c.coordinate_set and jid(c) == to_id { to_exists = True; } }
    if not from_exists or not to_exists { return None; }
    for existing in [root -->][?:NaviJacConnection] { if existing.floor_id == floor_id and existing.from_id == from_id and existing.to_id == to_id { return existing; } }
    return root ++> NaviJacConnection(floor_id=floor_id, from_id=from_id, to_id=to_id, cost=cost);
}

def:pub verify_connection_edge(edge_id: str, verified: bool, blocked: bool) -> NaviJacConnection | None {
    for item in [root -->][?:NaviJacConnection] { if jid(item) == edge_id { item.verification_status = "Verified" if verified else "Unverified"; item.blocked = blocked; return item; } }
    return None;
}

def:pub get_graph_validation_summary(floor_id: str) -> dict {
    data = get_floor_editor_data(floor_id);
    rooms = data["rooms"] as list[NaviJacRoom]; checkpoints = data["checkpoints"] as list[NaviJacCheckpoint]; connections = data["connections"] as list[NaviJacConnection];
    missing = 0; unverified = 0; verified = 0; placed = 0;
    for r in rooms {
        confirmed = False;
        for c in checkpoints { if c.room_id == jid(r) and c.coordinate_set and c.placement_status == "Verified entrance" { confirmed = True; } }
        if confirmed { placed += 1; } else { missing += 1; }
    }
    for e in connections { if not e.blocked and e.verification_status == "Verified" { verified += 1; } elif not e.blocked { unverified += 1; } }
    return {"rooms": len(rooms), "pending_rooms": missing, "placed_rooms": placed, "verified_edges": verified, "unverified_edges": unverified, "message": str(placed) + " rooms confirmed; " + str(missing) + " rooms require doorway confirmation; " + str(unverified) + " connections unverified."};
}

def:pub find_verified_route(floor_id: str, start_id: str, destination_checkpoint_id: str) -> dict {
    start_found = False; destination_found = False;
    for c in [root -->][?:NaviJacCheckpoint] { if c.floor_id == floor_id and jid(c) == start_id and c.coordinate_set and c.placement_status == "Verified entrance" { start_found = True; } if c.floor_id == floor_id and jid(c) == destination_checkpoint_id and c.coordinate_set and c.placement_status == "Verified entrance" { destination_found = True; } }
    if not start_found or not destination_found { return {"status": "pending", "message": "Starting point or room entrance is awaiting placement and verification.", "waypoints": []}; }
    distances: dict[str, float] = {start_id: 0.0}; previous: dict[str, str] = {}; visited: list[str] = []; candidates: list[str] = [start_id];
    while len(candidates) > 0 {
        current = candidates[0]; best = distances[current];
        for candidate in candidates { if distances[candidate] < best { current = candidate; best = distances[candidate]; } }
        candidates = [candidate for candidate in candidates if candidate != current];
        if current == destination_checkpoint_id { break; }
        if current not in visited {
            visited = visited + [current];
            for e in [root -->][?:NaviJacConnection] {
                if e.floor_id == floor_id and e.from_id == current and e.verification_status == "Verified" and not e.blocked {
                    alternate = distances[current] + e.cost;
                    if e.to_id not in distances or alternate < distances[e.to_id] { distances[e.to_id] = alternate; previous[e.to_id] = current; if e.to_id not in candidates { candidates = candidates + [e.to_id]; } }
                }
            }
        }
    }
    if destination_checkpoint_id not in distances { return {"status": "unreachable", "message": "No route exists using verified, unblocked connections.", "waypoints": []}; }
    path: list[str] = [destination_checkpoint_id]; cursor = destination_checkpoint_id;
    while cursor != start_id { cursor = previous[cursor]; path = [cursor] + path; }
    return {"status": "ready", "message": "Route uses verified connections only. Cost is in administrator-defined map units.", "waypoints": path, "cost": distances[destination_checkpoint_id]};
}
