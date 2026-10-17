# Deploy NaviJac

The app needs a Python/Jac server and persistent graph storage. A static-only
host such as GitHub Pages cannot provide accounts, private maps, or timetables.
No workflow automatically merges or deploys changes.

## Container deployment

Build `Dockerfile` and run one instance on a container host with HTTPS:

```sh
docker build -t navijac:local .
docker run --rm -p 8000:8000 -v navijac-data:/app/.jac/data navijac:local
```

Configure the host's persistent disk at `/app/.jac/data`. The application listens
on `PORT` (default `8000`) and the host should terminate HTTPS. Keep one instance
when using the local store; multiple replicas need a separately configured shared
database and a shared signing secret. Back up the disk before upgrades.

`deploy/start.py` starts the production server without development hot reload.
It generates a private session-signing key in the persistent disk, reuses it on
restart, and never prints it. Alternatively set `NAVIJAC_JWT_SECRET` securely in
the host's environment settings (at least 32 random characters). Never put its
value in source, build arguments, chat, or deployment logs. The production profile
disables the bundled admin portal and its default account bootstrap.

No OpenAI key or external database is needed for a single-instance deployment.
For a managed host, connect this repository, select Docker, mount the persistent
disk, and deploy the reviewed commit. Do not enable automatic deployments unless
separately requested. Domain/account access and any paid hosting plan must be
available before a public deployment can be verified.

## Verify after deployment

1. Check the HTTPS home page and `/openapi.json`.
2. Open the featured route, verify all rooms load, confirm a manual starting
   location, and select a destination. Directions are an illustrative plan demo,
   not a surveyed or accessible-route guarantee.
3. Register a test creator, create a private draft, publish/unpublish it, and
   verify the public directory after unpublishing.
4. Save a personal timetable entry, restart the deployed instance, and confirm
   both the entry and owned map survive with the mounted disk.
5. Confirm the deployment uses the production profile and no default admin
   account is created. Report the actual public URL only after these checks.

Real GPS proximity detection, surveyed route geometry, and arbitrary creator-map
floor editing are not completed by fixing startup and deployment. They remain
separate development work; do not present this demo as live indoor tracking.
