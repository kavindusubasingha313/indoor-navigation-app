enum NaviJacRole: str {
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
        floor_count: int = 1;
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
