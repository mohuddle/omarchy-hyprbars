#!/usr/bin/env bash
# Rebuild hyprbars against the running Hyprland and reload it.
# Pins come from hyprland-plugins/hyprpm.toml (Hyprland commit → plugins commit).
set -euo pipefail

PLUGIN_SRC="${PLUGIN_SRC:-$HOME/.local/src/hyprland-plugins}"
PLUGIN_SO="${PLUGIN_SO:-$HOME/.local/share/hyprland/plugins/hyprbars.so}"
PLUGIN_REPO="${PLUGIN_REPO:-https://github.com/hyprwm/hyprland-plugins.git}"

need() { command -v "$1" >/dev/null || { echo "missing: $1" >&2; exit 1; }; }
need git
need make
need pkg-config
need hyprctl
pkg-config --exists hyprland || { echo "pkg-config cannot find hyprland" >&2; exit 1; }

hypr_commit="$(hyprctl version | sed -n 's/.*commit \([0-9a-f]\{40\}\).*/\1/p' | head -n1)"
if [[ -z "$hypr_commit" ]]; then
  echo "could not parse Hyprland commit from: hyprctl version" >&2
  hyprctl version >&2
  exit 1
fi

if [[ ! -d "$PLUGIN_SRC/.git" ]]; then
  mkdir -p "$(dirname "$PLUGIN_SRC")"
  git clone --filter=blob:none "$PLUGIN_REPO" "$PLUGIN_SRC"
fi

git -C "$PLUGIN_SRC" fetch --depth 1 origin
git -C "$PLUGIN_SRC" fetch --depth 1 origin "$hypr_commit" 2>/dev/null || true
# hyprpm.toml lives on the default branch; fetch enough history for the pin table.
git -C "$PLUGIN_SRC" fetch --depth 1 origin HEAD

pin="$(git -C "$PLUGIN_SRC" show origin/HEAD:hyprpm.toml \
  | awk -v c="$hypr_commit" '
      $0 ~ c {
        if (match($0, /"([0-9a-f]{40})",[[:space:]]*"([0-9a-f]{40})"/, a)) {
          print a[2]
          exit
        }
      }
    ')"

if [[ -z "$pin" ]]; then
  echo "no hyprpm.toml pin for Hyprland $hypr_commit" >&2
  echo "hyprland-plugins may not have a matching release yet." >&2
  exit 1
fi

echo "Hyprland  $hypr_commit"
echo "plugins   $pin"

git -C "$PLUGIN_SRC" fetch --depth 1 origin "$pin"
git -C "$PLUGIN_SRC" checkout --detach "$pin"
make -C "$PLUGIN_SRC/hyprbars" clean || true
make -C "$PLUGIN_SRC/hyprbars" all

mkdir -p "$(dirname "$PLUGIN_SO")"
cp -f "$PLUGIN_SRC/hyprbars/hyprbars.so" "$PLUGIN_SO"

if hyprctl plugin list | grep -q hyprbars; then
  hyprctl plugin unload "$PLUGIN_SO" || true
fi
hyprctl plugin load "$PLUGIN_SO"
hyprctl reload
echo "loaded: $PLUGIN_SO"
hyprctl plugin list
