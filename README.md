# grok-build-boxed

Container image for running `grok-build` in a **strictly isolated environment**, keeping it away from your host system and personal data.

**Why containerized?**
Grok's built-in sandbox is not safe enough (for me) to run directly on my host system:
- Without `--sandbox=strict`, Grok has **read access to the entire filesystem** including your home directory, synced cloud drives, and any other mounted paths.
- `--sandbox=strict` would limit access to the subtree it is launched from, but if that happens to be your home directory, your data is still exposed.
- Additionally, `--sandbox=strict` currently has a bug and does not work reliably, which prevents Grok from even starting. See `olwig/pkgbuild#21`.

Running Grok inside a container solves these security issues: it is fully caged, has no access to your host filesystem (except the explicitly mounted `~/.grok-build-boxed/`), cannot interfere with your system, and is reusable.

## Build

```bash
podman build -t grok-build-boxed .
```

Or use the latest workflow-built image from GHCR:

```bash
podman pull ghcr.io/olwig/grok-build-boxed:latest
```

## Run

Temporary (with automatic cleanup via `--rm`):

Use self-built local image:

```bash
podman run -it --rm \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	--userns=keep-id:uid=1000,gid=1000 \
	localhost/grok-build-boxed:latest
```

Or use GHCR latest image:

```bash
podman run -it --rm \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	--userns=keep-id:uid=1000,gid=1000 \
	ghcr.io/olwig/grok-build-boxed:latest
```

Named container (persists so you can start/stop and reuse it):

Use self-built local image:

```bash
podman run -it \
	--name grok-build-boxed \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	--userns=keep-id:uid=1000,gid=1000 \
	--hostname grok-build-boxed \
	localhost/grok-build-boxed:latest
```

Or use GHCR latest image:

```bash
podman run -it \
	--name grok-build-boxed \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	--userns=keep-id:uid=1000,gid=1000 \
	--hostname grok-build-boxed \
	ghcr.io/olwig/grok-build-boxed:latest
```

Working with the named container:

```bash
# stop running instance
podman stop grok-build-boxed

# restart stopped instance (in background)
podman start grok-build-boxed

# connect directly (interactive, like "start + attach" in one step)
podman start -ai grok-build-boxed

# open an additional shell in running container
podman exec -it grok-build-boxed fish

# open a shell as root to inspect or change anything inside the container
podman exec -it --user root grok-build-boxed fish

# open a shell as builder to use sudo for package installs
podman exec -it --user builder grok-build-boxed fish

# check status
podman ps -a --filter name=grok-build-boxed

# delete container when no longer needed
podman rm grok-build-boxed
```

## Details

- `~/.grok-build-boxed/` is mounted into `/home/grokuser` for persistent data.
- `--userns=keep-id` keeps file ownership aligned with the host user.
- See `Containerfile` for the image definition and defaults.