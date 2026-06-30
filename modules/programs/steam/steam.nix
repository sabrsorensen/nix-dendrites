{
  lib,
  ...
}:
{
  flake.modules.nixos.steam =
    { config, lib, ... }:
    lib.mkIf (config.my.host.features.gui && config.my.host.features.steam) {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-unwrapped"
        ];
    };
}
