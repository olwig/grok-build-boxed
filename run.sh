#!/usr/bin/env bash

set -euo pipefail

# pull newer image before running container, if newer image exists
do_pull=true

# Hash the host working directory to keep the mounted path short and isolate sessions over different open containers
do_hash_work=true

# if true use localhost image instead of ghcr.io image
localhost_image=false

# if true, share the host network namespace with the container
do_host_network=false

for arg in "$@"; do
	if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
		echo "Usage: $(basename "$0") [OPTIONS] [-- CONTAINER_ARGS...]"
		echo
		echo "Options:"
		echo "  --pull         Pull a newer image before running, if one exists. On by default."
		echo "  --no-pull      Do not pull an image before running."
		echo "  --localhost-image  Use localhost image instead of ghcr.io image."
		echo "  --hash-work    Mount the current directory at a short hashed path. On by default."
		echo "  --no-hash-work Mount the current directory at /work/<host path>."
		echo "  --host-network Give the container the host network namespace."
		echo "  --help, -h     Show this help message and exit."
		echo
		echo "Argument separator:"
		echo "  --             Not an option; passes everything after this directly to the container."
		echo
		echo "Notes:"
		echo "  Unknown flags are an error. See --help."
		echo "  Arguments after '--' are passed to the container."
		echo "  When a flag and its --no- form both appear, the last one wins."
		echo
		echo "Examples:"
		echo "  $(basename "$0")"
		echo "  $(basename "$0") --no-pull --no-hash-work"
		echo "  $(basename "$0") --host-network"
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
		--no-pull)
			do_pull=false
			;;
		--hash-work)
			do_hash_work=true
			;;
		--no-hash-work)
			do_hash_work=false
			;;
		--localhost-image)
			localhost_image=true
			;;
		--host-network)
			do_host_network=true
			;;
		-*)
			echo "error: $arg is not a valid flag. See --help." >&2
			exit 1
			;;
	esac
done

echo "Running container with args: ${container_args[*]}"

image_repo="ghcr.io/olwig/grok-build-boxed"
if [ "$localhost_image" = true ]; then
	image_repo="localhost/olwig/grok-build-boxed"
fi

image="$image_repo:latest"

pull_args=()
if [ "$do_pull" = true ]; then
	pull_args=(--pull=newer)
fi

network_args=()
if [ "$do_host_network" = true ]; then
	network_args=(--network=host)
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
	"${network_args[@]}" \
	-v ~/.grok-build-boxed/:/home/grokuser:Z \
	-v "$HOST_WORK":"$CONTAINER_WORK":Z \
	-w "$CONTAINER_WORK" \
	-v "$XDG_RUNTIME_DIR/pipewire-0:/tmp/pipewire-0:Z" \
	-e XDG_RUNTIME_DIR=/tmp \
	--userns=keep-id:uid=1000,gid=1000 \
	--hostname grok-build-boxed \
	"$image" "${container_args[@]}"
