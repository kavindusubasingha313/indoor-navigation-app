"""Browser acceptance checks against the real full-stack entry point."""

import os
import secrets
import shutil

import pytest
from playwright.sync_api import expect

from conftest import ROOT, Server


@pytest.fixture(scope="module")
def frontend(project):
    # Reuse only installed client packages/tools, never graph data or app output.
    for relative in (".jac/client/node_modules", ".jac/bin"):
        source = ROOT / relative
        if source.exists():
            target = project / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(source, target, symlinks=True,
                            ignore=shutil.ignore_patterns(".vite"))
    server = Server(project, frontend=True)
    try:
        yield server.start()
    finally:
        server.stop()


@pytest.fixture(scope="session")
def browser_type_launch_args(browser_type_launch_args):
    # Optional local system browser; Actions uses Playwright's pinned Chromium.
    executable = os.environ.get("NAVIJAC_CHROMIUM_EXECUTABLE")
    if executable:
        return {**browser_type_launch_args, "executable_path": executable}
    return browser_type_launch_args


def open_app(page, frontend, path="/"):
    errors = []
    page.on("pageerror", lambda error: errors.append(str(error)))
    page.goto(frontend.url + path)
    return errors


def test_home_and_theme_persistence(page, frontend):
    errors = open_app(page, frontend)
    expect(page.get_by_role("heading", name="Navigate Any Building. Create Your Own Indoor Maps.")).to_be_visible()
    page.get_by_role("button", name="Dark", exact=True).click()
    expect(page.locator("html")).to_have_class("dark")
    page.reload()
    expect(page.locator("html")).to_have_class("dark")
    page.get_by_role("button", name="Light", exact=True).click()
    expect(page.locator("html")).not_to_have_class("dark")
    assert not errors, errors


def test_route_room_loading_and_manual_confirmation(page, frontend):
    errors = open_app(page, frontend, "/maps/sumanadasa/first-floor/route")
    expect(page.get_by_role("heading", name="Find a room", exact=True)).to_be_visible()
    start = page.get_by_role("combobox", name="Current indoor location")
    expect(start.locator("option")).to_have_count(15)
    start.select_option(index=1)
    page.get_by_role("button", name="Confirm my location", exact=True).click()
    expect(page.get_by_text("MANUAL_CONFIRMED", exact=False)).to_be_visible()
    page.get_by_role("combobox", name="Destination room").select_option(index=2)
    page.get_by_role("button", name="Get directions", exact=True).click()
    expect(page.get_by_text("Demo directions via the lobby", exact=False)).to_be_visible()
    assert not errors, errors


def register_creator(page, frontend):
    errors = open_app(page, frontend, "/creator")
    form = page.locator("form").filter(has=page.get_by_role("button", name="Create account", exact=True))
    form.get_by_label("Email", exact=True).fill("ci_" + secrets.token_hex(6) + "@example.com")
    form.get_by_label("Password", exact=True).fill(secrets.token_urlsafe(24))
    form.get_by_role("button", name="Create account", exact=True).click()
    expect(page.get_by_role("button", name="Sign out", exact=True)).to_be_visible()
    return errors


def test_creator_draft_publication_and_unpublication(page, frontend):
    errors = register_creator(page, frontend)
    name = "Browser map " + secrets.token_hex(4)
    page.get_by_label("Building name", exact=True).fill(name)
    page.get_by_role("button", name="Create private draft", exact=True).click()
    card = page.locator("article").filter(has=page.get_by_role("heading", name=name, exact=True))
    expect(card.get_by_text("Private draft", exact=True)).to_be_visible()
    card.get_by_role("button", name="Publish map", exact=True).click()
    expect(card.get_by_role("button", name="Unpublish", exact=True)).to_be_visible()
    card.get_by_role("button", name="Unpublish", exact=True).click()
    expect(card.get_by_text("Private draft", exact=True)).to_be_visible()
    assert not errors, errors


def test_personal_timetable_can_save_session(page, frontend):
    errors = register_creator(page, frontend)
    page.get_by_role("link", name="My timetable", exact=True).click()
    page.get_by_label("Subject or event", exact=True).fill("Browser test lecture")
    page.get_by_role("button", name="Save session", exact=True).click()
    expect(page.get_by_text("Browser test lecture", exact=True)).to_be_visible()
    page.reload()
    expect(page.get_by_text("Browser test lecture", exact=True)).to_be_visible()
    assert not errors, errors


def test_mobile_home_has_no_horizontal_overflow(page, frontend):
    page.set_viewport_size({"width": 390, "height": 844})
    errors = open_app(page, frontend)
    expect(page.get_by_role("heading", name="Navigate Any Building. Create Your Own Indoor Maps.")).to_be_visible()
    assert page.evaluate("document.documentElement.scrollWidth <= window.innerWidth")
    assert not errors, errors
