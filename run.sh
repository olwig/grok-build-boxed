#!/usr/bin/env bash

set -euo pipefail

# pull newer image before running container, if newer image exists
do_pull=false

# use sudo-latest image tag instead of latest, which is just a ordinary user
use_sudo=false

# Hash the host working directory to keep the mounted path short and isolate sessions over different open containers
do_hash_work=false

# if true use localhost image instead of ghcr.io image
localhost_image=false

for arg in "$@"; do
	if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
		echo "Usage: $(basename "$0") [OPTIONS] [-- CONTAINER_ARGS...]"
		echo
		echo "Options:"
		echo "  --pull         Pull newer image before running container, if a newer image exists."
		echo "  --sudo         Use sudo-latest image tag instead of latest (ordinary user image)."
		echo "  --localhost-image  Use localhost image instead of ghcr.io image."
		echo "  --hash-work    Use a hashed version of the current working directory as the container working directory."
		echo "  --help, -h     Show this help message and exit."
		echo
		echo "Argument separator:"
		echo "  --             Not an option; passes everything after this directly to the container."
		echo
		echo "Notes:"
		echo "  Unrecognized arguments before '--' are forwarded to the container command."
		echo
		echo "Examples:"
		echo "  $(basename "$0") --pull"
		echo "  $(basename "$0") --sudo --hash-work"
		echo "  $(basename "$0") -- --version"
		exit 0
	fi
done

container_args=()
pass_through=false
for arg in "$@"; do
	if [ "$pass_through" = true ]; then
		container_args+=("$arg")
		continue
	fi

	case "$arg" in
		--)
			pass_through=true
			;;
		--pull)
			do_pull=true
			;;
		--sudo)
			use_sudo=true
			;;
		--hash-work)
			do_hash_work=true
			;;
		--localhost-image)
			localhost_image=true
			;;
	esac
done

echo "Running container with args: ${container_args[*]}"

image_repo="ghcr.io/olwig/grok-build-boxed"
if [ "$localhost_image" = true ]; then
	image_repo="localhost/olwig/grok-build-boxed"
fi

if [ "$use_sudo" = true ]; then
	image="$image_repo:sudo-latest"
else
	image="$image_repo:latest"
fi

pull_args=()
if [ "$do_pull" = true ]; then
	pull_args=(--pull=newer)
fi

HOST_WORK="$PWD"
CONTAINER_WORK="/work/$HOST_WORK"
if [ "$do_hash_work" = true ]; then
	hash=$(printf '%s' "$HOST_WORK" | sha256sum | cut -c1-7)
	CONTAINER_WORK="/mnt/$hash"
fi

# create user dir if not exist
if [ ! -d ~/.grok-build-boxed ]; then
	mkdir -p ~/.grok-build-boxed
fi

podman run -it --rm \
	"${pull_args[@]}" \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	-v "$HOST_WORK":"$CONTAINER_WORK":Z \
	-w "$CONTAINER_WORK" \
	-v "$XDG_RUNTIME_DIR/pipewire-0:/tmp/pipewire-0:Z" \
	-e XDG_RUNTIME_DIR=/tmp \
	--userns=keep-id:uid=1000,gid=1000 \
	--hostname grok-build-boxed \
	"$image" "${container_args[@]}"
