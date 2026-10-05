{ inputs, ... }:
{
  flake.modules.nixos.unit-failure-alerts =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.unitFailureAlerts;
      gotifyEnv = config.services.gotify.environment;
      tokenFile = "${inputs.nix-secrets}/env_files/unit-failure-alerts.env";
    in
    {
      options.my.unitFailureAlerts = {
        gotifyUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default =
            if config.services.gotify.enable then
              "http://${gotifyEnv.GOTIFY_SERVER_LISTENADDR}:${toString gotifyEnv.GOTIFY_SERVER_PORT}"
            else
              null;
          defaultText = lib.literalMD "the local Gotify listener when this host runs Gotify";
          description = "Gotify base URL that failed-unit alerts are posted to.";
        };
        interval = lib.mkOption {
          type = lib.types.str;
          default = "2min";
          description = "How often failed units are checked (also the delay after boot).";
        };
      };
      options.my.host.features.unitFailureAlerts =
        lib.mkEnableOption "Gotify alerts when a systemd unit enters the failed state";
      config = lib.mkIf config.my.host.features.unitFailureAlerts (
        if builtins.pathExists tokenFile then
          import ./_unit-failure-alerts.nix (args // { inherit cfg tokenFile; })
        else
          {
            warnings = [
              ''
                my.host.features.unitFailureAlerts is enabled on ${config.my.host.name}
                but ${tokenFile} is missing from nix-secrets, so no alerts are sent.
                Create a Gotify application, then add a sops-encrypted dotenv file
                there containing GOTIFY_TOKEN=<application token>.
              ''
            ];
          }
      );
    };
}
