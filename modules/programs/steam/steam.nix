{
  lib,
  ...
}:
{
  flake.modules.nixos.steam =
    { config, lib, ... }:
    lib.mkIf (config.my.host.features.gui && config.my.host.features.steam) {
      nix.settings.extra-substituters = [ "https://nix-gaming.cachix.org" ];
      nix.settings.extra-trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];

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
