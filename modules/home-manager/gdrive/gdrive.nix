{
  inputs,
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
      hostTokenSecretName = "rclone/gdrive/${lib.strings.toLower hostName}_token";
      secretFile = "${inputs.nix-secrets}/rclone/gdrive.yaml";
    in
    {
      options.my.gdrive.enable = lib.mkEnableOption "an rclone Google Drive mount at ~/gdrive";

      config = lib.mkIf cfg.enable {
        sops.secrets."rclone/gdrive/client_id" = {
          sopsFile = secretFile;
          key = "client_id";
        };
        sops.secrets."rclone/gdrive/client_secret" = {
          sopsFile = secretFile;
          key = "client_secret";
        };
        sops.secrets.${hostTokenSecretName} = {
          sopsFile = secretFile;
          key = lib.removePrefix "rclone/gdrive/" hostTokenSecretName;
        };

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
      };
    };
}
