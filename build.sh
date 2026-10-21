#!/bin/bash
set -euo pipefail

tag_prefix="localhost/olwig/grok-build-boxed"
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

git clone --depth 1 https://aur.archlinux.org/grok-build-bin.git "$workdir/grok-build-bin"

srcinfo="$workdir/grok-build-bin/.SRCINFO"
if [ ! -s "$srcinfo" ]; then
	echo "error: AUR grok-build-bin clone has no .SRCINFO" >&2
	exit 1
fi
pkgver=$(awk -F ' = ' '/^[[:space:]]*pkgver = / { print $2; exit }' "$srcinfo")
pkgrel=$(awk -F ' = ' '/^[[:space:]]*pkgrel = / { print $2; exit }' "$srcinfo")

if [ -z "${pkgver}" ] || [ -z "${pkgrel}" ]; then
	echo "error: could not read pkgver and pkgrel from AUR grok-build-bin" >&2
	exit 1
fi
case "$pkgver" in
	*[!0-9A-Za-z._-]*)
		echo "error: invalid pkgver '$pkgver'" >&2
		exit 1
		;;
esac
case "$pkgrel" in
	*[!0-9]*)
		echo "error: invalid pkgrel '$pkgrel'" >&2
		exit 1
		;;
esac

podman build \
	--build-arg "GROK_BUILD_VERSION=$pkgver" \
	--build-arg "GROK_BUILD_PKGREL=$pkgrel" \
	-t "$tag_prefix:$pkgver" \
	-t "$tag_prefix:latest" \
	-f Containerfile .
