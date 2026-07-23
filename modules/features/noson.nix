{ ... }:
{
  flake.modules.nixos.noson =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.noson {
      home-manager.users.sam.home.packages = [ pkgs.noson ];
      networking.firewall.allowedTCPPorts = [
        1400
        3400
      ];
    };
}
