#!/bin/sh

# install grok-pwd as a symlink into user local bin, override if it exists
mkdir -p "$HOME/.local/bin"
ln -sf "$PWD/grok-pwd" "$HOME/.local/bin/grok-pwd"
