{
  flake.modules.nixos.users-atlasuponraiden =
    args@{ config, lib, ... }:
    lib.mkIf (config.my.host.name == "AtlasUponRaiden" && config.my.host.home.enable) (
      import ./_users.nix
    );
}
