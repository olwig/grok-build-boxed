#!/bin/bash

tag_prefix="localhost/olwig/grok-build-boxed"

podman build \
    -t "$tag_prefix:latest" \
    -f Containerfile .

podman build \
    --from "$tag_prefix:latest" \
    -t "$tag_prefix:sudo-latest" \
    -f Containerfile.sudo .