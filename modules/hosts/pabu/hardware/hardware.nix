{ inputs, lib, ... }:
let
in
{
  flake.modules.nixos.hardware-pabu =
    args@{
      config,
      lib,
      ...
    }:
    lib.mkIf (config.my.host.name == "Pabu") (
      import ./_hardware.nix (
        args
        // { }
      )
    );
}
