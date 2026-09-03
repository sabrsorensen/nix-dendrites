#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <config|output|image-config|image-output|final-config> <host>" >&2
  exit 1
fi

mode=$1
host=$(tr '[:upper:]' '[:lower:]' <<<"$2")

if [[ ! $host =~ ^[a-z0-9-]+$ ]]; then
  echo "Host names may contain only lowercase letters, digits, and hyphens." >&2
  exit 1
fi

case "$mode" in
  config | output)
    configuration="${host}-bootstrap"
    ;;
  image-config | image-output)
    configuration="${host}-bootstrap-image"
    ;;
  final-config)
    configuration="${host}-bootstrap"
    nix eval --raw ".#nixosConfigurations.\"${configuration}\".config.my.host.bootstrap.finalConfigName"
    printf '\n'
    exit 0
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    exit 1
    ;;
esac

# Bootstrap configurations are explicit flake outputs.  Evaluating the host
# name first gives a clear error if the requested variant is not declared.
nix eval --raw ".#nixosConfigurations.\"${configuration}\".config.networking.hostName" >/dev/null
printf '%s\n' "$configuration"
