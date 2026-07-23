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
    in
    {
      options.my.blocky.prometheus = {
        enable = lib.mkEnableOption "Blocky Prometheus metrics endpoint";
        httpPort = lib.mkOption {
          type = lib.types.port;
          default = 4000;
        };
        path = lib.mkOption {
          type = lib.types.str;
          default = "/metrics";
        };
      };

      config = lib.mkIf config.my.host.services.blocky {
        environment.systemPackages = [ pkgs.blocky ];
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
              mapping."${domain}" = "127.0.0.1:1053";
            };
            customDNS = {
              customTTL = "1h";
              mapping = {
                "geo.hivebedrock.network" = network.atlasuponraiden;
                "hivebedrock.network" = network.atlasuponraiden;
                "play.inpvp.net" = network.atlasuponraiden;
                "mco.lbsg.net" = network.atlasuponraiden;
                "play.galaxite.net" = network.atlasuponraiden;
                "play.enchanted.gg" = network.atlasuponraiden;
              };
            };
            blocking = {
              denylists.ads = [
                "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews/hosts"
                "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.txt"
                "https://raw.githubusercontent.com/kboghdady/youTube_ads_4_pi-hole/master/youtubelist.txt"
                "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt"
              ];
              allowlists.ads = [
                "*.amplitude.com"
                "*.looker.com"
              ];
              clientGroupsBlock.default = [ "ads" ];
            };
          };
        };
        networking.firewall = {
          allowedTCPPorts = [ 53 ] ++ lib.optionals cfg.prometheus.enable [ cfg.prometheus.httpPort ];
          allowedUDPPorts = [ 53 ];
        };
        systemd.services.blocky = {
          after = [ "coredns.service" ];
          wants = [ "coredns.service" ];
        };
      };
    };
}
