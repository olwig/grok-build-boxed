# grok-build-boxed

Container image for running `grok-build` in a **strictly isolated environment**, keeping it away from your host system and personal data.

**Why containerized?**
Grok's built-in sandbox is not safe enough (for me) to run directly on my host system:
- Without `--sandbox=strict`, Grok has **read access to the entire filesystem** including your home directory, synced cloud drives, and any other mounted paths.
- `--sandbox=strict` would limit access to the subtree it is launched from, but if that happens to be your home directory, your data is still exposed.
- Additionally, `--sandbox=strict` currently has a bug and does not work reliably, which prevents Grok from even starting. See `olwig/pkgbuild#21`.

Running Grok inside a container solves these security issues: it is fully caged, has no access to your host filesystem (except the explicitly mounted `~/.grok-build-boxed/`), cannot interfere with your system, and is reusable.

## TODO

- Match the container user folder to the host path so copied workspace paths work instantly.
- Clean up CLI args.
- Revise the README.
- Have Grok review this project.
- Support build targets for localhost, docker.io, and ghcr.io.
- Check that pull only fetches when the image is missing or newer.
- Choose the Arch base tag. `docker.io/archlinux/archlinux:latest` is rebuilt about daily, so the GitHub Actions layer cache is reused only while that digest stays the same. `docker.io/library/archlinux:latest` is the official Docker Hub image and is rebuilt about weekly, so `:latest` still moves and a rebuild in the same week can reuse the package and tini layer. An immutable date tag such as `base-YYYYMMDD.0.<job>` keeps that layer reusable until the tag is changed; Arch stays on that snapshot until then. The Actions cache is already on. A miss rebuilds like a cold build, and unused cache entries drop after 7 days. There is no `pacman -Syu`: the base system stays at the image snapshot, and only the packages named in the Containerfile are installed from the mirrors at build time.

## Build

```bash
./build.sh
```

`./build.sh` reads the AUR `grok-build-bin` version and tags
`localhost/olwig/grok-build-boxed:latest` and
`localhost/olwig/grok-build-boxed:<version>`.

Or use the latest workflow-built image from GHCR:

```bash
podman pull ghcr.io/olwig/grok-build-boxed:latest
```

Pin the Grok Build version installed in an image with that version tag, for example `ghcr.io/olwig/grok-build-boxed:1.0.62`.

## Image updates

Published tags are `:latest` and `:<grok version>` (the Grok Build version installed in that image).

The image is published when `Containerfile` or `.github/workflows/build-n-push-ghcr.yml` changes on `main`, when the workflow is run manually, or when the daily check sees a new AUR `grok-build-bin` version (`pkgver` or `pkgrel`). A matching package version does not publish a new image.

The Arch base is `docker.io/archlinux/archlinux:latest`. A new digest of that tag rebuilds every layer. While that digest is unchanged, a new `grok-build-bin` version rebuilds the layer that installs Grok Build. GitHub Actions reuses the unchanged layers from its cache.

## Sudo

`grokuser` can use sudo without a password. The process still starts as uid 1000 (`grokuser`).

```bash
podman run -it --rm --pull=newer \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	-v "$PWD":/work:Z \
	-w /work \
	--userns=keep-id:uid=1000,gid=1000 \
	--hostname grok-build-boxed \
	ghcr.io/olwig/grok-build-boxed:latest
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

Temporary session with a disposable host work folder:

```bash
WORK="$(mktemp -d)" podman run -it --rm \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	-v "$WORK":/work:Z \
	-w /work \
	--userns=keep-id:uid=1000,gid=1000 \
	--hostname grok-build-boxed \
	localhost/grok-build-boxed:latest
```

If you use the bundled `./grok-build-boxed` launcher script, it creates a temporary host work directory for you and prints the path before the container starts.

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
- `./run.sh` passes `--pull=newer` to Podman, so Podman fetches the image only when it is missing or newer. `--no-pull` skips that check.
- `./run.sh` mounts the current directory at `/mnt/` plus the first 7 hex characters of the SHA-256 of that path, and starts there. `--no-hash-work` mounts it at `/work/<host path>` instead. `--hash-work` turns the hashed path back on when it follows `--no-hash-work`.
- `./run.sh --host-network` passes `--network=host` to Podman. The container then uses the host network namespace: host interfaces, services on localhost, and host ports. Without the flag it keeps Podman's own network.
- See `Containerfile` for the image definition and defaults.

## Working with projects

Work directly inside `/home/grokuser` in the container. This is your mounted host folder (`~/.grok-build-boxed/`), so all files persist on the host.

You can use either workflow:

- Clone repositories from inside the container into `/home/grokuser`.
- Or clone/copy from the host into `~/.grok-build-boxed/` and open/use them in the container.

You can also add an additional mount if you prefer. Keep `~/.grok-build-boxed/` mounted to `/home/grokuser` because Grok stores config, metadata, and caches there. Mount extra folders as subfolders inside `/home/grokuser`, for example:

> ⚠️ **Security note:** Be very careful what you mount into the container. Anything mapped into the container may also be readable (and potentially writable) by Grok, depending on permissions. Only mount directories you explicitly want Grok to access.

```bash
WORK="$HOME/work" podman run -it --rm \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	-v "$WORK":/work:Z \
	-w /work \
	--userns=keep-id:uid=1000,gid=1000 \
	--hostname grok-build-boxed \
	ghcr.io/olwig/grok-build-boxed:latest
```
