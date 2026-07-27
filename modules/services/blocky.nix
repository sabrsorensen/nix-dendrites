{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
in
{
  flake.modules.nixos.blocky =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.blocky;
      networkConfig = network;
      localDomain = domain;
    in
    {
      options.my.blocky = {
        enable = lib.mkEnableOption "Blocky DNS service";

        prometheus = {
          enable = lib.mkEnableOption "Prometheus metrics endpoint for Blocky";

          httpPort = lib.mkOption {
            type = lib.types.port;
            default = 4000;
            description = "HTTP port used by Blocky for Prometheus metrics.";
          };

          path = lib.mkOption {
            type = lib.types.str;
            default = "/metrics";
            description = "HTTP path used by Blocky to expose Prometheus metrics.";
          };
        };
      };

      config = lib.mkIf config.my.host.services.blocky {
        environment.systemPackages = with pkgs; [
          blocky.out
        ];
        services.blocky = {
          enable = true;
          settings = {
            ports = {
              dns = 53;
              http = cfg.prometheus.httpPort;
            };

            prometheus = lib.mkIf cfg.prometheus.enable {
              enable = true;
              path = cfg.prometheus.path;
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
              allowlists = {
                ads = [
                  "|
                    *.amplitude.com
                    *.looker.com"
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

        networking.firewall.allowedTCPPorts = [
          53
        ]
        ++ lib.optionals cfg.prometheus.enable [ cfg.prometheus.httpPort ];
        networking.firewall.allowedUDPPorts = [ 53 ];
      };
    };
}
