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

def:pub get_public_maps() -> list[NaviJacMap] {
    return [root -->][?:NaviJacMap, is_public];
}

def:pub create_public_map(name: str, description: str) -> NaviJacMap | None {
    clean_name = name.strip();
    if len(clean_name) == 0 {
        return None;
    }
    return root ++> NaviJacMap(name=clean_name, description=description.strip());
}

def:pub upload_floor_plan(map_id: str, image_data: str, image_type: str) -> NaviJacMap | None {
    if len(image_data) == 0 or len(image_data) > 7000000 {
        return None;
    }
    if image_type != "image/png" and image_type != "image/jpeg" {
        return None;
    }
    for building in [root -->][?:NaviJacMap, is_public] {
        if jid(building) == map_id {
            building.floor_plan_data = image_data;
            building.floor_plan_type = image_type;
            return building;
        }
    }
    return None;
}
