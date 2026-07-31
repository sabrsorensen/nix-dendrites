{ inputs, ... }:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
in
{
  flake.modules.nixos.rpi-network =
    args@{ config, lib, ... }:
    lib.mkIf (config.my.host.is.rpi && config.my.host.address != null) (
      import ./_content.nix (args // { inherit network; })
    );
}
