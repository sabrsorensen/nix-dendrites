#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <config|output|image-config|image-output|final-config> <host>" >&2
  exit 1
fi

mode=$1
host=$2

case "$mode" in
  config)
    predicate='builtins.match ".*-bootstrap$" output.name != null && (output.buildProduct or null) == null'
    attr='output.configuration'
    ;;
  output)
    predicate='builtins.match ".*-bootstrap$" output.name != null && (output.buildProduct or null) == null'
    attr='output.name'
    ;;
  image-config)
    predicate='builtins.match ".*-bootstrap-image$" output.name != null && (output.buildProduct or null) == "sdImage"'
    attr='output.configuration'
    ;;
  image-output)
    predicate='builtins.match ".*-bootstrap-image$" output.name != null && (output.buildProduct or null) == "sdImage"'
    attr='output.name'
    ;;
  final-config)
    nix eval --raw --impure --expr "
      let
        flake = builtins.getFlake (toString ./.);
        inventory = builtins.getAttr \"${host}\" flake.outputs.lib.hostInventory;
        bootstrapOutputs = builtins.filter (
          output: builtins.match \".*-bootstrap$\" output.name != null && (output.buildProduct or null) == null
        ) inventory.outputs;
      in
      if bootstrapOutputs == [] then
        \"${host}\"
      else
        let
          cfg = flake.outputs.nixosConfigurations.\${(builtins.head bootstrapOutputs).configuration}.config;
        in
        cfg.my.host.bootstrap.finalConfigName
    "
    exit 0
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    exit 1
    ;;
esac

nix eval --raw --impure --expr "
  let
    flake = builtins.getFlake (toString ./.);
    inventory = builtins.getAttr \"${host}\" flake.outputs.lib.hostInventory;
    outputs = builtins.filter (output: ${predicate}) inventory.outputs;
  in
  if outputs == [] then
    builtins.throw \"No matching bootstrap target found for ${host}\"
  else
    let
      output = builtins.head outputs;
    in
    ${attr}
"
