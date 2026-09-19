{ inputs, ... }:
let
  module =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.jovian-nixos.nixosModules.default ];
      config = lib.mkIf (config.my.host.platform == "steamdeck") (import ./_jovian.nix args);
    };
in
module
