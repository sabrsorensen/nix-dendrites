{
  ...
}:
{
  flake.modules.nixos.blocky =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services.blocky;
      networkConfig = config.systemConstants.network;
      localDomain = config.systemConstants.domain;
    in
    {
      options.my.services.blocky.enable = lib.mkEnableOption "Blocky DNS service";

      config = lib.mkIf cfg.enable {
        services.blocky = {
          enable = true;
          settings = {
            ports = {
              dns = 53;
              http = 4000;
            };

            upstreams.groups.default = [
              "1.1.1.1"
              "9.9.9.9"
            ];

            conditional = {
              fallbackUpstream = false;
              mapping = {
                "${localDomain}" = "127.0.0.1:1053";
              };
            };

            customDNS = {
              customTTL = "1h";
              mapping = {
                "geo.hivebedrock.network" = networkConfig.atlasuponraiden;
                "hivebedrock.network" = networkConfig.atlasuponraiden;
                "play.inpvp.net" = networkConfig.atlasuponraiden;
                "mco.lbsg.net" = networkConfig.atlasuponraiden;
                "play.galaxite.net" = networkConfig.atlasuponraiden;
                "play.enchanted.gg" = networkConfig.atlasuponraiden;
              };
            };

            blocking = {
              denylists = {
                ads = [
                  "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
                  "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.txt"
                  "https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/youtubelist.txt"
                  "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt"
                ];
              };
              clientGroupsBlock.default = [ "ads" ];
            };
          };
        };

        systemd.services.blocky = {
          after = [ "coredns.service" ];
          wants = [ "coredns.service" ];
        };

        networking.firewall.allowedTCPPorts = [ 53 ];
        networking.firewall.allowedUDPPorts = [ 53 ];
      };
    };
}
