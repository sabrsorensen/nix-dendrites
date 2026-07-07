{
  flake.modules.nixos.noson =
    {
      config,
      lib,
      ...
    }:
    lib.mkIf config.my.host.features.noson {
      networking.firewall.allowedTCPPorts = [
        1400
        3400
      ];
    };

  flake.modules.homeManager.noson =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.host.features.noson {
      home.packages = [ pkgs.noson ];
    };
}
