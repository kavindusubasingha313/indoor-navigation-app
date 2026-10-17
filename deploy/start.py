"""Start one production Jac instance with a persistent private signing key."""

import os
from pathlib import Path
import secrets


def signing_key(directory):
    supplied = os.environ.get("NAVIJAC_JWT_SECRET")
    if supplied:
        if len(supplied) < 32:
            raise RuntimeError("NAVIJAC_JWT_SECRET must contain at least 32 characters")
        return supplied
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / ".jwt-signing-key"
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError:
        key = path.read_text().strip()
    else:
        key = secrets.token_urlsafe(48)
        with os.fdopen(descriptor, "w") as stream:
            stream.write(key + "\n")
    if len(key) < 32:
        raise RuntimeError("Persisted signing key is invalid; restore it from a secure backup")
    return key


def main():
    os.environ["NAVIJAC_JWT_SECRET"] = signing_key(Path(".jac/data"))
    port = int(os.environ.get("PORT", "8000"))
    if not 1 <= port <= 65535:
        raise RuntimeError("PORT must be between 1 and 65535")
    os.execvp("jac", ["jac", "start", "--profile", "production", "--port", str(port), "main.jac"])


if __name__ == "__main__":
    main()
