{ ... }:
{
  flake.modules.nixos.noson =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.features.noson && config.my.host.home.enable){
      networking.firewall.allowedTCPPorts = [
        1400
        3400
      ];
      home-manager.users.sam.home.packages = [ pkgs.noson ];
    };
}
