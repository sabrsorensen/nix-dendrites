#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <host> <ssh-target> [nixos-anywhere args...]" >&2
  exit 1
fi

host=$1
target=$2
shift 2

bootstrap_configuration=$("$(dirname "$0")/bootstrap-target.sh" config "$host")

exec nix run github:nix-community/nixos-anywhere -- \
  --flake ".#${bootstrap_configuration}" \
  "$target" \
  "$@"
