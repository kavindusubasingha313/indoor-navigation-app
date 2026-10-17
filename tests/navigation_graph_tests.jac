import from uuid { uuid4 }
import from services.naviJacService {
    NaviJacCheckpoint, NaviJacConnection, find_verified_route
}

def graph() -> dict {
    floor_id = str(uuid4());
    ids: list[str] = [];
    for i in range(3) {
        point = NaviJacCheckpoint(
            floor_id=floor_id, room_id=str(i), room_number=i,
            coordinate_set=True, placement_status="Verified entrance"
        );
        root.shared ++> point;
        ids.append(jid(point));
    }
    return {"floor": floor_id, "a": ids[0], "b": ids[1], "c": ids[2]};
}

def connect(g: dict, start: str, end: str, cost: float = 1.0,
            status: str = "Verified", blocked: bool = False,
            provenance: str = "ADMIN_ENTERED", approved: bool = False) {
    root.shared ++> NaviJacConnection(
        floor_id=g["floor"] as str, from_id=g[start] as str,
        to_id=g[end] as str, cost=cost, verification_status=status,
        blocked=blocked, provenance=provenance, experimental_approved=approved
    );
}

def route(g: dict, experimental: bool = False) -> dict {
    return find_verified_route(g["floor"] as str, g["a"] as str,
                               g["c"] as str, experimental);
}

test "weighted shortest path" {
    g = graph();
    connect(g, "a", "c", 10.0);
    connect(g, "a", "b", 2.0);
    connect(g, "b", "c", 3.0);
    result = route(g);
    assert result["status"] == "ready";
    assert result["cost"] == 5.0;
    assert result["waypoints"] == [g["a"], g["b"], g["c"]];
}

test "blocked edge excluded" {
    g = graph();
    connect(g, "a", "c", blocked=True);
    assert route(g)["status"] == "unreachable";
}

test "unverified edge excluded" {
    g = graph();
    connect(g, "a", "c", status="Unverified");
    assert route(g)["status"] == "unreachable";
}

test "experimental approval and opt in required" {
    g = graph();
    connect(g, "a", "c", status="Pending",
            provenance="EXPERIMENTAL_PROPOSAL", approved=True);
    assert route(g)["status"] == "unreachable";
    assert route(g, True)["status"] == "ready";
    unapproved = graph();
    connect(unapproved, "a", "c", status="Pending",
            provenance="EXPERIMENTAL_PROPOSAL", approved=False);
    assert route(unapproved, True)["status"] == "unreachable";
}

test "edges remain directed" {
    g = graph();
    connect(g, "c", "a");
    assert route(g)["status"] == "unreachable";
}

test "other floor edges excluded" {
    g = graph();
    other = {"floor": str(uuid4()), "a": g["a"], "c": g["c"]};
    connect(other, "a", "c");
    assert route(g)["status"] == "unreachable";
}

test "unconfirmed endpoint rejected" {
    g = graph();
    result = find_verified_route(g["floor"] as str, "missing", g["c"] as str);
    assert result["status"] == "pending";
    assert result["waypoints"] == [];
}
