{
  ...
}:
{
  flake.modules.nixos.blocky =
    {
      config,
      ...
    }:
    let
      networkConfig = config.systemConstants.network;
      readBuildValue =
        path:
        builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
      localDomain = readBuildValue "domain.txt";
    in
    {
      services.blocky = {
        enable = true;
        settings = {
          ports.dns = 53;

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
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"
                "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"
                "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.txt"
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
}
