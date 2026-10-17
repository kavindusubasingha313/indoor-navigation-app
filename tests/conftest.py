"""Run the real Jac CLI in disposable copies; never reset developer graph data."""

import os
from pathlib import Path
import secrets
import shutil
import socket
import subprocess
import time

import pytest
import requests

ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture(scope="module")
def project(tmp_path_factory):
    destination = tmp_path_factory.mktemp("navijac") / "app"
    # Copy source and configuration only, including tests. Generated dependencies
    # may be reused for frontend tests, but graph data and compiler caches cannot.
    shutil.copytree(
        ROOT,
        destination,
        ignore=shutil.ignore_patterns(
            ".git", ".jac", "node_modules", "dist", ".pytest_cache",
            "__pycache__", "test-results", ".env", ".env.*",
            ".venv", ".venvs", ".cache",
        ),
    )
    yield destination


class Server:
    def __init__(self, project, frontend=False):
        self.project = project
        self.frontend = frontend
        self.process = None
        self.log = None
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            self.port = sock.getsockname()[1]
        self.url = f"http://127.0.0.1:{self.port}"

    def start(self):
        self.log = (self.project / "server.log").open("a")
        command = ["jac", "start", "--dev", "--port", str(self.port)]
        command += ["main.jac"] if self.frontend else [
            "--no_client", "services/naviJacService.jac"
        ]
        self.process = subprocess.Popen(
            command, cwd=self.project, stdout=self.log,
            stderr=subprocess.STDOUT, start_new_session=True,
        )
        deadline = time.monotonic() + 90
        path = "/" if self.frontend else "/openapi.json"
        while time.monotonic() < deadline:
            if self.process.poll() is not None:
                break
            try:
                response = requests.get(self.url + path, timeout=2)
                if response.status_code == 200:
                    return self
            except requests.RequestException:
                pass
            time.sleep(0.25)
        self.stop()
        pytest.fail("Jac server failed readiness:\n" +
                    (self.project / "server.log").read_text()[-14000:])

    def stop(self):
        if self.process is not None:
            # Terminate this fixture's process group, including Vite children.
            import signal
            try:
                os.killpg(self.process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                self.process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(self.process.pid, signal.SIGKILL)
                self.process.wait(timeout=5)
            self.process = None
        if self.log is not None:
            self.log.close()
            self.log = None


@pytest.fixture(scope="module")
def backend(project):
    server = Server(project)
    try:
        yield server.start()
    finally:
        server.stop()


def api(server, session, endpoint, **body):
    response = session.post(
        server.url + "/function/" + endpoint, json=body, timeout=15
    )
    assert response.status_code == 200, f"{endpoint}: HTTP {response.status_code}"
    envelope = response.json()
    assert envelope["ok"], f"{endpoint}: {envelope.get('error')}"
    return envelope["data"]["result"]


def _token(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if key in ("access_token", "token") and isinstance(item, str):
                return item
            found = _token(item)
            if found:
                return found
    return None


def login(server, identity, credential):
    session = requests.Session()
    response = session.post(server.url + "/user/login", json={
        "identity": identity, "credential": credential,
    }, timeout=15)
    assert response.status_code == 200, "Test user login failed"
    token = _token(response.json())
    assert token, "Login did not issue an access token"
    session.headers["Authorization"] = "Bearer " + token
    return session


def account(server):
    identity = {"type": "username", "value": "ci_" + secrets.token_hex(8)}
    credential = {"type": "password", "password": secrets.token_urlsafe(24)}
    response = requests.post(server.url + "/user/register", json={
        "identities": [identity], "credential": credential,
    }, timeout=15)
    assert response.status_code == 201, "Test user registration failed"
    return login(server, identity, credential), identity, credential


def create_map(server, session):
    result = api(server, session, "create_owned_map", name="CI private map",
                 description="Isolated test data", location="Test")
    assert isinstance(result, dict), "create_owned_map must return a node, not the ++> result list"
    node = result
    assert node["is_public"] is False
    return node
