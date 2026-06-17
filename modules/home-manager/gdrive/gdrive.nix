{
  config,
  lib,
  ...
}:
{
  flake.modules.homeManager.gdrive =
    {
      config,
      lib,
      osConfig ? { },
      ...
    }:
    let
      cfg = config.my.gdrive;
      hostName =
        if osConfig ? my && osConfig.my ? host && osConfig.my.host ? name then
          osConfig.my.host.name
        else
          config.my.host.name;
      hostTokenSecretName =
        {
          Kamino = "rclone/gdrive/kamino_token";
          ZaphodBeeblebrox = "rclone/gdrive/zaphodbeeblebrox_token";
          AtlasUponRaiden = "rclone/gdrive/atlasuponraiden_token";
        }
        .${hostName} or "rclone/gdrive/${lib.strings.toLower hostName}_token";
      secretNames = [
        "rclone/gdrive/client_id"
        "rclone/gdrive/client_secret"
        hostTokenSecretName
      ];
      hasSecret = name: config.sops.secrets ? "${name}";
      missingSecrets = builtins.filter (name: !(hasSecret name)) secretNames;
      hasAllSecrets = missingSecrets == [ ];
      missingSecretsMessage = builtins.concatStringsSep ", " missingSecrets;
    in
    {
      options.my.gdrive.enable = lib.mkEnableOption "an rclone Google Drive mount at ~/gdrive";

      config = lib.mkMerge [
        {
          warnings = lib.optionals (cfg.enable && !hasAllSecrets) [
            "Google Drive mount is enabled, but these sops secrets are missing: ${missingSecretsMessage}"
          ];
        }
        (lib.mkIf (cfg.enable && hasAllSecrets) {
          programs.rclone = {
            enable = true;
            remotes.gdrive = {
              config = {
                type = "drive";
                scope = "drive";
              };
              secrets = {
                client_id = config.sops.secrets."rclone/gdrive/client_id".path;
                client_secret = config.sops.secrets."rclone/gdrive/client_secret".path;
                token = config.sops.secrets.${hostTokenSecretName}.path;
              };
              mounts."" = {
                enable = true;
                mountPoint = "${config.home.homeDirectory}/gdrive";
                options = {
                  dir-cache-time = "72h";
                  poll-interval = "15s";
                };
              };
            };
          };
        })
      ];
    };
}
