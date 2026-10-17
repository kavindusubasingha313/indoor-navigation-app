"""Signing-key persistence must survive restarts without insecure defaults."""

import importlib.util
from pathlib import Path
import stat

import pytest


@pytest.fixture
def startup():
    path = Path(__file__).resolve().parents[1] / "deploy/start.py"
    spec = importlib.util.spec_from_file_location("startup", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_generated_signing_key_survives_restart(startup, tmp_path, monkeypatch):
    monkeypatch.delenv("NAVIJAC_JWT_SECRET", raising=False)
    first = startup.signing_key(tmp_path)
    assert len(first) >= 32
    assert startup.signing_key(tmp_path) == first
    assert stat.S_IMODE((tmp_path / ".jwt-signing-key").stat().st_mode) == 0o600


def test_short_supplied_key_is_rejected(startup, tmp_path, monkeypatch):
    monkeypatch.setenv("NAVIJAC_JWT_SECRET", "too-short")
    with pytest.raises(RuntimeError, match="at least 32"):
        startup.signing_key(tmp_path)
