#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <ssh-target>" >&2
  exit 1
fi

target=$1

ssh "$target" 'sudo bootstrap-enroll'
