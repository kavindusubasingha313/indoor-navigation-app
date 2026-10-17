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
node NaviJacMap { has name: str, description: str = "", owner_id: str = "", source_id: str = "", location: str = "", is_featured: bool = False, is_public: bool = True, floor_count: int = 1, floor_plan_data: str = "", floor_plan_type: str = ""; }
node NaviJacFloor { has building_name: str, department: str = "", university: str = "", floor_name: str = "", level_number: int = 1, calibration_m_per_px: float = 0.0909, calibration_note: str = "Room 1 horizontal length: 14 m over approximately 154 px; source illustration only.", distortion_warning: str = "Estimated dimensions follow schematic image proportions and are not independently verified.", original_map_id: str = ""; }
node NaviJacRoom { has floor_id: str, room_number: int, original_name: str, length_m: float, width_m: float, measurement_status: str = "Estimated, unverified", category: str = "Unspecified", description: str = "", notes: str = "", x: float = 0.0, y: float = 0.0, display_label: str = ""; }
node NaviJacGeometry { has floor_id: str, geometry_kind: str, x1: float = 0.0, y1: float = 0.0, x2: float = 0.0, y2: float = 0.0, label: str = ""; }
node NaviJacCheckpoint { has floor_id: str, room_id: str, room_number: int, checkpoint_type: NaviJacCheckpointType = NaviJacCheckpointType.ROOM_ENTRANCE, placement_status: str = "Pending Placement", x: float = 0.0, y: float = 0.0, coordinate_set: bool = False, nearest_waypoint_id: str = "", qr_url: str = ""; }
node NaviJacWaypoint { has floor_id: str, label: str = "Corridor point", x: float = 0.0, y: float = 0.0; }
node NaviJacConnection { has floor_id: str, from_id: str, to_id: str, cost: float = 1.0, verification_status: str = "Unverified", provenance: str = "ADMIN_ENTERED", experimental_approved: bool = False, blocked: bool = False, accessible: bool = False; }
node NaviJacTimetableEntry { has subject: str, weekday: str, start_time: str, end_time: str, building_id: str = "", room_id: str = "", location_name: str = "", notes: str = ""; }

# Public read-only discovery endpoints use the shared catalogue.
def:pub get_public_maps() -> list[NaviJacMap] { return [root.shared -->][?:NaviJacMap, is_public]; }
def:pub get_featured_demo() -> NaviJacMap | None { for m in [root.shared -->][?:NaviJacMap] { if m.is_featured { return m; } } return None; }
def:pub get_public_room_profile(room_id: str) -> NaviJacRoom | None { for r in [root.shared -->][?:NaviJacRoom] { if jid(r) == room_id { return r; } } return None; }

# Creator projects live under the authenticated owner's root; public copies are published into root.shared.
def:protect get_owned_maps() -> list[NaviJacMap] { return [root -->][?:NaviJacMap]; }
def:protect create_owned_map(name: str, description: str, location: str) -> NaviJacMap | None {
    clean = name.strip(); if len(clean) == 0 { return None; }
    return root ++> NaviJacMap(name=clean, description=description.strip(), location=location.strip(), owner_id=str(jid(root)), is_public=False);
}
def:protect update_owned_map(map_id: str, name: str, description: str) -> NaviJacMap | None {
    for m in [root -->][?:NaviJacMap] { if jid(m) == map_id and m.owner_id == str(jid(root)) { m.name = name.strip(); m.description = description.strip(); return m; } }
    return None;
}
def:protect publish_owned_map(map_id: str, publish: bool) -> NaviJacMap | None {
    for draft in [root -->][?:NaviJacMap] {
        if jid(draft) == map_id and draft.owner_id == str(jid(root)) {
            draft.is_public = publish;
            for copy in [root.shared -->][?:NaviJacMap] { if copy.source_id == map_id { copy.is_public = publish; copy.name = draft.name; copy.description = draft.description; return draft; } }
            if publish { root.shared ++> NaviJacMap(name=draft.name, description=draft.description, owner_id=draft.owner_id, source_id=map_id, location=draft.location, is_public=True, floor_count=draft.floor_count, floor_plan_data=draft.floor_plan_data, floor_plan_type=draft.floor_plan_type); }
            return draft;
        }
    }
    return None;
}
def:protect upload_floor_plan(map_id: str, image_data: str, image_type: str) -> NaviJacMap | None {
    if len(image_data) == 0 or len(image_data) > 7000000 { return None; }
    if image_type != "image/png" and image_type != "image/jpeg" { return None; }
    for m in [root -->][?:NaviJacMap] { if jid(m) == map_id and m.owner_id == str(jid(root)) { m.floor_plan_data = image_data; m.floor_plan_type = image_type; return m; } }
    return None;
}

def:protect get_my_timetable() -> list[NaviJacTimetableEntry] {
    return [root -->][?:NaviJacTimetableEntry];
}

def _valid_time(value: str) -> bool {
    parts = value.split(":");
    if len(parts) != 2 { return False; }
    hour = int(parts[0]); minute = int(parts[1]);
    return hour >= 0 and hour < 24 and minute >= 0 and minute < 60;
}

def _time_minutes(value: str) -> int {
    parts = value.split(":");
    return int(parts[0]) * 60 + int(parts[1]);
}

def:protect create_timetable_entry(subject: str, weekday: str, start_time: str, end_time: str, building_id: str, room_id: str, location_name: str, notes: str) -> dict {
    days: list[str] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    if len(subject.strip()) == 0 { return {"ok": False, "message": "Enter an event or subject name."}; }
    if weekday not in days { return {"ok": False, "message": "Choose a valid weekday."}; }
    if not _valid_time(start_time) or not _valid_time(end_time) or _time_minutes(end_time) <= _time_minutes(start_time) { return {"ok": False, "message": "End time must be later than a valid start time."}; }
    for existing in [root -->][?:NaviJacTimetableEntry] {
        if existing.weekday == weekday and _time_minutes(start_time) < _time_minutes(existing.end_time) and _time_minutes(end_time) > _time_minutes(existing.start_time) { return {"ok": False, "message": "This session overlaps another saved session."}; }
    }
    root ++> NaviJacTimetableEntry(subject=subject.strip(), weekday=weekday, start_time=start_time, end_time=end_time, building_id=building_id.strip(), room_id=room_id.strip(), location_name=location_name.strip(), notes=notes.strip());
    return {"ok": True, "message": "Timetable session saved."};
}

def:protect preview_timetable_csv(csv_text: str) -> dict {
    lines = csv_text.strip().split(chr(10));
    rows: list[dict] = [];
    errors: list[str] = [];
    if len(lines) < 2 { return {"rows": rows, "errors": ["Paste a header row and at least one timetable row."], "valid": False}; }
    header = [h.strip().lower() for h in lines[0].split(",")];
    required: list[str] = ["subject", "weekday", "start_time", "end_time"];
    for col in required { if col not in header { errors = errors + ["CSV is missing the required column: " + col]; } }
    if len(errors) > 0 { return {"rows": rows, "errors": errors, "valid": False}; }
    subject_i = header.index("subject"); weekday_i = header.index("weekday"); start_i = header.index("start_time"); end_i = header.index("end_time");
    location_i = header.index("location") if "location" in header else -1;
    for line_no in range(1, len(lines)) {
        cells = [c.strip() for c in lines[line_no].split(",")];
        if len(cells) != len(header) { errors = errors + ["Row " + str(line_no + 1) + " has an unexpected number of columns."]; }
        else {
            subject = cells[subject_i]; weekday = cells[weekday_i]; start_value = cells[start_i]; end_value = cells[end_i]; location = cells[location_i] if location_i >= 0 else "";
            if len(subject) == 0 or not _valid_time(start_value) or not _valid_time(end_value) or _time_minutes(end_value) <= _time_minutes(start_value) { errors = errors + ["Row " + str(line_no + 1) + " has an invalid subject or time range."]; }
            else { rows = rows + [{"subject": subject, "weekday": weekday, "start_time": start_value, "end_time": end_value, "location_name": location}]; }
        }
    }
    return {"rows": rows, "errors": errors, "valid": len(errors) == 0};
}

# Public featured demo initialization is idempotent and never resets existing rooms or graph geometry.
def ensure_featured_record(floor_id: str) {
    found = False;
    for m in [root.shared -->][?:NaviJacMap] { if m.is_featured { found = True; } }
    if not found {
        root.shared ++> NaviJacMap(name="Dr. L. H. Sumanadasa Building", description="Electrical Engineering · University of Moratuwa", location="University of Moratuwa", owner_id="system", is_featured=True, is_public=True);
    }
}

def:pub seed_sumanadasa_floor() -> str {
    for f in [root.shared -->][?:NaviJacFloor] {
        if f.building_name == "Dr. L. H. Sumanadasa Building" and f.floor_name == "Ground Floor" { fid = jid(f); ensure_featured_record(fid); seed_sumanadasa_rooms(fid); return fid; }
    }
    ensure_featured_record("");
    featured_id = "";
    for m in [root.shared -->][?:NaviJacMap] { if m.is_featured { featured_id = jid(m); } }
    floor = root.shared ++> NaviJacFloor(building_name="Dr. L. H. Sumanadasa Building", department="Electrical Engineering", university="University of Moratuwa", floor_name="Ground Floor", calibration_m_per_px=0.0909, calibration_note="Estimated from the printed 6 m dimension grid in the supplied ground-floor plan; image-derived, not surveyed.", distortion_warning="The schematic is reconstructed from a supplied plan image. Dimension grid and visible openings are interpreted; verify all dimensions, door clear widths and accessible routes on site.", original_map_id=featured_id);
    fid = jid(floor); seed_sumanadasa_rooms(fid); return fid;
}

def seed_sumanadasa_rooms(floor_id: str) {
    names: list[str] = ["IT unit (NDT)", "Female toilet", "Store room", "Male toilet", "Computer lab (RCDF)", "Seminar room (ITSDL)", "Staff lounge", "Ladies lunch room", "Library lobby", "Bindery section", "Bindery stores", "AQ stores", "Technical services division", "Gents lunch room"];
    lengths: list[float] = [12.0, 6.0, 6.0, 6.0, 12.0, 12.0, 12.0, 12.0, 54.0, 18.0, 12.0, 18.0, 24.0, 12.0];
    widths: list[float] = [12.0, 6.0, 6.0, 6.0, 12.0, 12.0, 12.0, 12.0, 12.0, 18.0, 18.0, 18.0, 18.0, 18.0];
    labels: list[str] = ["IT unit (NDT)", "Toilet · female", "Store room", "Toilet · male", "Computer lab (RCDF)", "Seminar room (ITSDL)", "Staff lounge", "Ladies lunch room", "Lobby", "Bindery section", "Bindery stores", "AQ stores", "Technical services division", "Gents lunch room"];
    for (i, name) in enumerate(names) {
        found = False;
        for r in [root.shared -->][?:NaviJacRoom] { if r.floor_id == floor_id and r.room_number == i + 1 { found = True; } }
        if not found {
            note = "Approximate bounding dimensions interpreted from the printed 6 m grid; not surveyed.";
            if i == 8 { note = "Open circulation lobby; outline is approximate and includes stair/core interruptions."; }
            if i == 5 or i == 7 { note = "The drawing shows WC subdivisions in this area; individual cubicle sizes are not reconstructed."; }
            root.shared ++> NaviJacRoom(floor_id=floor_id, room_number=i + 1, original_name=name, display_label=labels[i], length_m=lengths[i], width_m=widths[i], measurement_status="Estimated from supplied ground-floor dimension grid", notes=note);
        }
    }
}

def:pub get_floor_editor_data(floor_id: str) -> dict {
    floor: NaviJacFloor | None = None; rooms: list[NaviJacRoom] = []; geometry: list[NaviJacGeometry] = []; checkpoints: list[NaviJacCheckpoint] = []; waypoints: list[NaviJacWaypoint] = []; connections: list[NaviJacConnection] = [];
    for f in [root.shared -->][?:NaviJacFloor] { if jid(f) == floor_id { floor = f; } }
    if floor is None { floor_key = seed_sumanadasa_floor(); floor = jobj(floor_key) as NaviJacFloor; }
    fid = jid(floor);
    for r in [root.shared -->][?:NaviJacRoom] { if r.floor_id == fid { rooms = rooms + [r]; } }
    if len(rooms) == 0 { seed_sumanadasa_rooms(fid); for r in [root.shared -->][?:NaviJacRoom] { if r.floor_id == fid { rooms = rooms + [r]; } } }
    for c in [root.shared -->][?:NaviJacCheckpoint] { if c.floor_id == fid { checkpoints = checkpoints + [c]; } }
    for r in rooms { has_cp = False; for c in checkpoints { if c.room_id == jid(r) { has_cp = True; } } if not has_cp { fresh = root.shared ++> NaviJacCheckpoint(floor_id=fid, room_id=jid(r), room_number=r.room_number); checkpoints = checkpoints + [fresh]; } }
    for g in [root.shared -->][?:NaviJacGeometry] { if g.floor_id == fid { geometry = geometry + [g]; } }
    for w in [root.shared -->][?:NaviJacWaypoint] { if w.floor_id == fid { waypoints = waypoints + [w]; } }
    for e in [root.shared -->][?:NaviJacConnection] { if e.floor_id == fid { connections = connections + [e]; } }
    return {"floor": floor, "rooms": rooms, "geometry": geometry, "checkpoints": checkpoints, "waypoints": waypoints, "connections": connections};
}

def:protect save_floor_editor_changes(floor_id: str, room_id: str, length_m: float, width_m: float, x: float, y: float, label: str, geometry_kind: str, x1: float, y1: float, x2: float, y2: float) -> dict {
    if length_m < 0.2 or length_m > 200 or width_m < 0.2 or width_m > 200 { return {"ok": False, "message": "Dimensions must be between 0.2 m and 200 m."}; }
    return {"ok": False, "message": "This featured demo is read-only. Create your own map to edit."};
}
def:protect calibrate_floor_scale(floor_id: str, known_distance_m: float, pixel_distance: float) -> dict { return {"ok": False, "message": "This featured demo is read-only; create your own map to calibrate."}; }
def:protect save_checkpoint_placement(floor_id: str, room_id: str, x: float, y: float, confirm_entrance: bool) -> NaviJacCheckpoint | None { return None; }
def:protect save_corridor_waypoint(floor_id: str, label: str, x: float, y: float) -> NaviJacWaypoint | None { return None; }
def:protect save_connection_edge(floor_id: str, from_id: str, to_id: str, cost: float) -> NaviJacConnection | None { return None; }
def:protect bulk_approve_experimental_edges(map_id: str) -> dict {
    owns_map = False;
    for map_item in [root -->][?:NaviJacMap] { if jid(map_item) == map_id and map_item.owner_id == str(jid(root)) and not map_item.is_featured { owns_map = True; } }
    if not owns_map { return {"ok": False, "approved": 0, "message": "Only the map owner can review this map."}; }
    floor_ids: list[str] = [];
    for floor_item in [root.shared -->][?:NaviJacFloor] { if floor_item.original_map_id == map_id { floor_ids = floor_ids + [jid(floor_item)]; } }
    approved = 0;
    for edge_item in [root.shared -->][?:NaviJacConnection] {
        if edge_item.provenance == "EXPERIMENTAL_PROPOSAL" and not edge_item.blocked and edge_item.verification_status == "Pending" {
            if edge_item.floor_id in floor_ids { edge_item.experimental_approved = True; approved += 1; }
        }
    }
    return {"ok": True, "approved": approved, "message": str(approved) + " existing experimental proposals approved. No routes were generated."};
}

def:protect verify_connection_edge(edge_id: str, verified: bool, blocked: bool) -> NaviJacConnection | None { return None; }
def:pub get_graph_validation_summary(floor_id: str) -> dict {
    data = get_floor_editor_data(floor_id); rooms = data["rooms"] as list[NaviJacRoom]; checkpoints = data["checkpoints"] as list[NaviJacCheckpoint]; connections = data["connections"] as list[NaviJacConnection]; pending = 0; verified = 0; unverified = 0;
    for r in rooms { placed = False; for cp in checkpoints { if cp.room_id == jid(r) and cp.coordinate_set and cp.placement_status == "Verified entrance" { placed = True; } } if not placed { pending += 1; } }
    for e in connections { if not e.blocked and e.verification_status == "Verified" { verified += 1; } elif not e.blocked { unverified += 1; } }
    return {"rooms": len(rooms), "pending_rooms": pending, "verified_edges": verified, "unverified_edges": unverified, "message": str(len(rooms) - pending) + " rooms confirmed; " + str(pending) + " rooms require doorway confirmation; " + str(unverified) + " connections unverified."};
}
def:pub find_verified_route(floor_id: str, start_id: str, destination_checkpoint_id: str, experimental_mode: bool = False) -> dict {
    start_ok = False;
    destination_ok = False;
    for cp in [root.shared -->][?:NaviJacCheckpoint] {
        if cp.floor_id == floor_id and jid(cp) == start_id and cp.coordinate_set and cp.placement_status == "Verified entrance" and cp.checkpoint_type == NaviJacCheckpointType.ROOM_ENTRANCE { start_ok = True; }
        if cp.floor_id == floor_id and jid(cp) == destination_checkpoint_id and cp.coordinate_set and cp.placement_status == "Verified entrance" and cp.checkpoint_type == NaviJacCheckpointType.ROOM_ENTRANCE { destination_ok = True; }
    }
    if not start_ok or not destination_ok { return {"status": "pending", "message": "Starting point or room entrance needs confirmation.", "waypoints": []}; }
    distances: dict[str, float] = {start_id: 0.0};
    previous: dict[str, str] = {};
    visited: list[str] = [];
    frontier: list[str] = [start_id];
    while len(frontier) > 0 {
        current = frontier[0];
        smallest = distances[current];
        for candidate in frontier { if distances[candidate] < smallest { current = candidate; smallest = distances[candidate]; } }
        frontier = [candidate for candidate in frontier if candidate != current];
        if current == destination_checkpoint_id { break; }
        if current not in visited {
            visited = visited + [current];
            for e in [root.shared -->][?:NaviJacConnection] {
                edge_allowed = e.verification_status == "Verified" or (experimental_mode and e.provenance == "EXPERIMENTAL_PROPOSAL" and e.experimental_approved);
                if e.floor_id == floor_id and e.from_id == current and edge_allowed and not e.blocked {
                    alternate = distances[current] + e.cost;
                    if e.to_id not in distances or alternate < distances[e.to_id] {
                        distances[e.to_id] = alternate;
                        previous[e.to_id] = current;
                        if e.to_id not in frontier { frontier = frontier + [e.to_id]; }
                    }
                }
            }
        }
    }
    if destination_checkpoint_id not in distances {
        message = "No verified, unblocked route connects these locations.";
        if experimental_mode { message = "No verified or explicitly approved experimental route connects these locations."; }
        return {"status": "unreachable", "message": message, "waypoints": []};
    }
    path: list[str] = [destination_checkpoint_id];
    cursor = destination_checkpoint_id;
    while cursor != start_id { cursor = previous[cursor]; path = [cursor] + path; }
    route_label = "Verified route" if not experimental_mode else "Experimental route through explicitly approved proposals";
    return {"status": "ready", "message": route_label + "; cost is administrator-defined map units.", "waypoints": path, "cost": distances[destination_checkpoint_id]};
}

def:protect get_my_timetable() -> list[NaviJacTimetableEntry] {
    return [root -->][?:NaviJacTimetableEntry];
}

def _valid_time(value: str) -> bool {
    parts = value.split(":");
    if len(parts) != 2 { return False; }
    hour = int(parts[0]);
    minute = int(parts[1]);
    return hour >= 0 and hour < 24 and minute >= 0 and minute < 60;
}

def _time_minutes(value: str) -> int {
    parts = value.split(":");
    return int(parts[0]) * 60 + int(parts[1]);
}

def _valid_weekday(day: str) -> bool {
    days: list[str] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return day in days;
}

def:protect create_timetable_entry(subject: str, weekday: str, start_time: str, end_time: str, building_id: str, room_id: str, location_name: str, notes: str) -> dict {
    if len(subject.strip()) == 0 { return {"ok": False, "message": "Enter an event or subject name."}; }
    if not _valid_weekday(weekday) { return {"ok": False, "message": "Choose a valid weekday."}; }
    if not _valid_time(start_time) or not _valid_time(end_time) or _time_minutes(end_time) <= _time_minutes(start_time) { return {"ok": False, "message": "End time must be later than a valid start time."}; }
    for existing in [root -->][?:NaviJacTimetableEntry] {
        if existing.weekday == weekday and _time_minutes(start_time) < _time_minutes(existing.end_time) and _time_minutes(end_time) > _time_minutes(existing.start_time) { return {"ok": False, "message": "This session overlaps another saved session."}; }
    }
    root ++> NaviJacTimetableEntry(subject=subject.strip(), weekday=weekday, start_time=start_time, end_time=end_time, building_id=building_id.strip(), room_id=room_id.strip(), location_name=location_name.strip(), notes=notes.strip());
    return {"ok": True, "message": "Timetable session saved."};
}

def:protect preview_timetable_csv(csv_text: str) -> dict {
    lines = csv_text.strip().split(chr(10));
    rows: list[dict] = [];
    errors: list[str] = [];
    if len(lines) < 2 { return {"rows": rows, "errors": ["Paste a header row and at least one timetable row."], "valid": False}; }
    header = [h.strip().lower() for h in lines[0].split(",")];
    required: list[str] = ["subject", "weekday", "start_time", "end_time"];
    for col in required { if col not in header { errors = errors + ["CSV is missing the required column: " + col]; } }
    if len(errors) > 0 { return {"rows": rows, "errors": errors, "valid": False}; }
    subject_i = header.index("subject"); weekday_i = header.index("weekday"); start_i = header.index("start_time"); end_i = header.index("end_time");
    location_i = header.index("location") if "location" in header else -1;
    for line_no in range(1, len(lines)) {
        cells = [c.strip() for c in lines[line_no].split(",")];
        if len(cells) != len(header) { errors = errors + ["Row " + str(line_no + 1) + " has an unexpected number of columns."]; }
        else {
            subject = cells[subject_i]; weekday = cells[weekday_i]; start_value = cells[start_i]; end_value = cells[end_i]; location = cells[location_i] if location_i >= 0 else "";
            if len(subject) == 0 or not _valid_weekday(weekday) or not _valid_time(start_value) or not _valid_time(end_value) or _time_minutes(end_value) <= _time_minutes(start_value) { errors = errors + ["Row " + str(line_no + 1) + " has an invalid subject, weekday, or time range."]; }
            else {
                overlaps_saved = False;
                for existing in [root -->][?:NaviJacTimetableEntry] { if existing.weekday == weekday and _time_minutes(start_value) < _time_minutes(existing.end_time) and _time_minutes(end_value) > _time_minutes(existing.start_time) { overlaps_saved = True; } }
                if overlaps_saved { errors = errors + ["Row " + str(line_no + 1) + " overlaps a saved session."]; }
                for prior in rows { if prior["weekday"] == weekday and _time_minutes(start_value) < _time_minutes(prior["end_time"] as str) and _time_minutes(end_value) > _time_minutes(prior["start_time"] as str) { overlaps_saved = True; } }
                if overlaps_saved { errors = errors + ["Row " + str(line_no + 1) + " overlaps another imported session."]; }
                rows = rows + [{"subject": subject, "weekday": weekday, "start_time": start_value, "end_time": end_value, "location_name": location}];
            }
        }
    }
    return {"rows": rows, "errors": errors, "valid": len(errors) == 0};
}

def:protect import_timetable_csv(csv_text: str) -> dict {
    result = preview_timetable_csv(csv_text);
    if not (result["valid"] as bool) { return {"ok": False, "message": "CSV validation found errors. Correct them before importing.", "errors": result["errors"]}; }
    rows = result["rows"] as list[dict];
    for row in rows {
        root ++> NaviJacTimetableEntry(subject=row["subject"] as str, weekday=row["weekday"] as str, start_time=row["start_time"] as str, end_time=row["end_time"] as str, location_name=row["location_name"] as str);
    }
    return {"ok": True, "message": str(len(rows)) + " timetable sessions imported."};
}
