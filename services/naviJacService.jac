enum NaviJacRole {
    ADMINISTRATOR = "administrator",
    MAP_CREATOR = "map_creator",
    PUBLIC_VIEWER = "public_viewer"
}

node NaviJacAccount {
    has display_name: str,
        role: NaviJacRole,
        email: str = "";
}

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

def:pub get_public_maps() -> list[NaviJacMap] {
    return [root -->][?:NaviJacMap, is_public];
}

def:pub create_public_map(name: str, description: str) -> NaviJacMap | None {
    clean_name = name.strip();
    if len(clean_name) == 0 { return None; }
    return root ++> NaviJacMap(name=clean_name, description=description.strip());
}

def:pub upload_floor_plan(map_id: str, image_data: str, image_type: str) -> NaviJacMap | None {
    if len(image_data) == 0 or len(image_data) > 7000000 { return None; }
    if image_type != "image/png" and image_type != "image/jpeg" { return None; }
    for building in [root -->][?:NaviJacMap, is_public] {
        if jid(building) == map_id {
            building.floor_plan_data = image_data;
            building.floor_plan_type = image_type;
            return building;
        }
    }
    return None;
}

def:pub seed_sumanadasa_floor() -> NaviJacFloor {
    floor: NaviJacFloor | None = None;
    for f in [root -->][?:NaviJacFloor] {
        if f.building_name == "Dr. L. H. Sumanadasa Building" and f.floor_name == "First Floor" { floor = f; }
    }
    if floor is None {
        floor = root ++> NaviJacFloor(
            building_name="Dr. L. H. Sumanadasa Building",
            department="Electrical Engineering",
            university="University of Moratuwa",
            floor_name="First Floor"
        );
        seed_sumanadasa_rooms(jid(floor));
    }
    return floor;
}

def seed_sumanadasa_rooms(floor_id: str) {
    names: list[str] = [
        "Electrical Engineering seminar room",
        "Senior staff common room",
        "Department office",
        "Head of the Department",
        "Electrical Engineering Board room",
        "Electrical Measurements Laboratory",
        "High Voltage Laboratory (Control Room)",
        "Staff room - Prof. N. Wickramarachchi",
        "Staff room",
        "Staff room - Dr. L. Weeramanckara",
        "Staff room - Prof. W.D.A.S. Rodrigo",
        "Staff room - Prof. J.P. Karunadasa",
        "Staff rooms - multiple academic staff",
        "Final Year Lecture Room",
        "Robotics and Automation Laboratory (section)",
        "Staff room - Dr. R.M.M. Ruwanthika",
        "Robotics and Automation Laboratory (section)",
        "Electrical Installations Laboratory",
        "Staff rooms - Contract Lecturers"
    ];
    lengths: list[float] = [14.0, 3.8, 3.9, 6.2, 6.3, 21.5, 9.5, 9.5, 6.5, 6.5, 9.5, 9.5, 9.5, 13.8, 5.9, 6.2, 11.8, 18.4, 7.7];
    widths: list[float] = [6.4, 6.4, 6.4, 6.4, 6.4, 6.4, 6.4, 5.4, 5.5, 5.4, 5.5, 5.4, 8.1, 6.4, 6.4, 6.4, 6.4, 6.4, 6.4];
    for i in range(19) {
        already_seeded = False;
        for r in [root -->][?:NaviJacRoom] {
            if r.floor_id == floor_id and r.room_number == i + 1 { already_seeded = True; }
        }
        if not already_seeded {
            name = names[i];
            room_note = "Width uses bounding extent; stepped boundary not represented." if i + 1 == 8 or i + 1 == 11 else "";
            room_note = "Numbered area includes multiple staff rooms; internal partitions not specified." if i + 1 == 13 else room_note;
            room_note = "Section of Robotics and Automation Laboratory; do not assume independent facility." if i + 1 == 15 or i + 1 == 17 else room_note;
            root ++> NaviJacRoom(floor_id=floor_id, room_number=i + 1, original_name=name, display_label=name, length_m=lengths[i], width_m=widths[i], notes=room_note, x=10.0 + (i % 7) * 12.0, y=15.0 + (i / 7) * 28.0);
        }
    }
}

def:pub get_floor_editor_data(floor_id: str) -> dict {
    floor: NaviJacFloor | None = None;
    rooms: list[NaviJacRoom] = [];
    geometry: list[NaviJacGeometry] = [];
    for f in [root -->][?:NaviJacFloor] { if jid(f) == floor_id { floor = f; } }
    if floor is None { floor = seed_sumanadasa_floor(); }
    fid = jid(floor);
    for r in [root -->][?:NaviJacRoom] { if r.floor_id == fid { rooms = rooms + [r]; } }
    for g in [root -->][?:NaviJacGeometry] { if g.floor_id == fid { geometry = geometry + [g]; } }
    return {"floor": floor, "rooms": rooms, "geometry": geometry};
}

def:pub save_floor_editor_changes(floor_id: str, room_id: str, length_m: float, width_m: float, x: float, y: float, label: str, geometry_kind: str, x1: float, y1: float, x2: float, y2: float) -> dict {
    floor: NaviJacFloor | None = None;
    for f in [root -->][?:NaviJacFloor] { if jid(f) == floor_id { floor = f; } }
    if floor is None { floor = seed_sumanadasa_floor(); }
    if length_m < 0.2 or length_m > 200.0 or width_m < 0.2 or width_m > 200.0 { return {"ok": False, "message": "Dimensions must be between 0.2 m and 200 m."}; }
    for r in [root -->][?:NaviJacRoom] {
        if jid(r) == room_id and r.floor_id == jid(floor) {
            r.length_m = length_m;
            r.width_m = width_m;
            r.x = x;
            r.y = y;
            r.display_label = label;
        }
    }
    if geometry_kind == "wall" or geometry_kind == "waypoint" {
        root ++> NaviJacGeometry(floor_id=jid(floor), geometry_kind=geometry_kind, x1=x1, y1=y1, x2=x2, y2=y2);
    }
    return {"ok": True, "message": "Floor edits saved. Dimension estimates remain unverified."};
}

def:pub calibrate_floor_scale(floor_id: str, known_distance_m: float, pixel_distance: float) -> dict {
    if known_distance_m <= 0 or pixel_distance <= 0 { return {"ok": False, "message": "Enter positive distances."}; }
    for f in [root -->][?:NaviJacFloor] {
        if jid(f) == floor_id {
            f.calibration_m_per_px = known_distance_m / pixel_distance;
            f.calibration_note = "User calibration from selected points; other dimensions remain estimated and may be distorted.";
            return {"ok": True, "scale": f.calibration_m_per_px, "message": f.distortion_warning};
        }
    }
    return {"ok": False, "message": "Floor not found."};
}
