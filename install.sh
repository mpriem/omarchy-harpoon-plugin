#!/usr/bin/env bash
# Install (or update) this checkout into Omarchy's plugin directory. Run it
# again after editing; the shell loads plugins from there, not from here.
set -euo pipefail
id=harpoon
src=$(cd "$(dirname "$0")" && pwd)
dst=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/$id
mkdir -p "$dst"
rsync -a --delete --exclude .git --exclude install.sh "$src/" "$dst/"
omarchy-plugin-validate "$dst"
omarchy plugin list 2>/dev/null | grep -qE "^$id\s+enabled" || omarchy plugin enable "$id"
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
echo "$id: installed to $dst"
