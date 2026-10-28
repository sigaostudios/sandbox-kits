#!/bin/sh
# Docker's workload install hooks run before this dependent mixin's hook.
set -eu
state=/home/agent/.local/state/codex
config=/home/agent/.codex
seed=/home/agent/.codex-create-seed

test -d "$state"
chown 1000:1000 "$state"
chmod 700 "$state"
if [ -L "$config" ]; then
    # Repeated install hooks must leave the live tree intact.
    test "$(readlink "$config")" = "$state"
    exit 0
fi
test -d "$config"
test ! -e "$seed"

# Retain every state file, including SQLite databases and future Codex additions.
# Never overwrite retained files with defaults from the fresh container.
cp -a -n "$config/." "$state/"
# Config/auth belong to Docker's create-time setup, including auth removal.
install -o 1000 -g 1000 -m 600 "$config/config.toml" "$state/config.toml"
if [ -f "$config/auth.json" ]; then
    install -o 1000 -g 1000 -m 600 "$config/auth.json" "$state/auth.json"
else
    rm -f "$state/auth.json"
fi
mv "$config" "$seed"
ln -s "$state" "$config"
chown -h 1000:1000 "$config"
