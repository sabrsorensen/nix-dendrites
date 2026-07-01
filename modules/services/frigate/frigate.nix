{ ... }:
{
  flake.modules.nixos.frigate =
  {
    config,
    lib,
    ...
  }:
  let
    cfg = config.my.services.frigate;
    pathSegment = cfg.pathSegment;
    localDomain = config.systemConstants.domain;
  in
  {
    options.my.services.frigate = {
      enable = lib.mkEnableOption "Frigate NVR service";

      pathSegment = lib.mkOption {
        type = lib.types.str;
        default = null;
      };

      siteHostName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "frigate";
      };
    };

    config = lib.mkIf cfg.enable {
      my.caddy =
        if cfg.siteHostName == null then
          {
            apexRoutes = [
              ''
                redir /${pathSegment} /${pathSegment}/
                reverse_proxy /${pathSegment}/* ${config.services.atuin.host}:${lib.toString config.services.atuin.port}
              ''
            ];
          }
        else
          {
            virtualHosts."${cfg.siteHostName}.{$DOMAIN}".routes = [
              ''
                reverse_proxy /* ${config.services.atuin.host}:${lib.toString config.services.atuin.port}
              ''
            ];
          };

      my.localDns.records = lib.optional (cfg.siteHostName != null) {
        hostname = cfg.siteHostName;
      };

      services.frigate = {
        enable = true;
        hostname = "frigate.${localDomain}";
        settings = {

        };
      };
    };
  };
}