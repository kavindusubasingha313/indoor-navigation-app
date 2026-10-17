"""Real HTTP, authentication, graph storage, and process-restart checks."""

import requests

from conftest import account, api, create_map, login


def test_map_survives_process_restart(backend):
    session, identity, credential = account(backend)
    created = create_map(backend, session)
    backend.stop()
    backend.start()
    session = login(backend, identity, credential)
    owned = api(backend, session, "get_owned_maps")
    restored = next(node for node in owned if node["_jac_id"] == created["_jac_id"])
    assert restored["name"] == "CI private map"
    assert restored["is_public"] is False
    assert restored["owner_id"] == created["owner_id"]


def test_other_owner_cannot_read_or_update_private_map(backend):
    owner, _, _ = account(backend)
    other, _, _ = account(backend)
    created = create_map(backend, owner)
    assert api(backend, other, "get_owned_maps") == []
    assert api(backend, other, "update_owned_map", map_id=created["_jac_id"],
               name="Unauthorized", description="") is None
    owned = api(backend, owner, "get_owned_maps")
    assert owned[0]["name"] == created["name"]


def test_anonymous_private_map_access_rejected(backend):
    response = requests.post(backend.url + "/function/get_owned_maps", json={}, timeout=15)
    assert response.status_code == 401


def test_publish_then_unpublish_hides_map_from_public(backend):
    owner, _, _ = account(backend)
    created = create_map(backend, owner)
    api(backend, owner, "publish_owned_map", map_id=created["_jac_id"], publish=True)
    anonymous = requests.Session()
    public = api(backend, anonymous, "get_public_maps")
    assert any(node["source_id"] == created["_jac_id"] for node in public)
    api(backend, owner, "publish_owned_map", map_id=created["_jac_id"], publish=False)
    public = api(backend, anonymous, "get_public_maps")
    assert all(node["source_id"] != created["_jac_id"] for node in public), (
        "Unpublished map remains visible to anonymous callers"
    )


def test_featured_map_initialization_is_repeatable(backend):
    anonymous = requests.Session()
    first = api(backend, anonymous, "seed_sumanadasa_floor")
    second = api(backend, anonymous, "seed_sumanadasa_floor")
    assert isinstance(first, str) and first
    assert second == first
    data = api(backend, anonymous, "get_floor_editor_data", floor_id=first)
    assert len(data["rooms"]) == 14
    assert len({node["room_number"] for node in data["rooms"]}) == 14
