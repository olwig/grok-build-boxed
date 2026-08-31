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

## Run

```bash
podman run -it --rm \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	--userns=keep-id:uid=1000,gid=1000 \
	localhost/grok-build-boxed:latest
```

## Details

- `~/.grok-build-boxed/` is mounted into `/home/grokuser` for persistent data.
- `--userns=keep-id` keeps file ownership aligned with the host user.
- See `Containerfile` for the image definition and defaults.