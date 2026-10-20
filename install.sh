#!/bin/sh


# install grok-build as a symlink into user local bin, override if it exists
mkdir -p "$HOME/.local/bin"
ln -sf "$PWD/run.sh" "$HOME/.local/bin/grok-build"
