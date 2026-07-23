{ inputs, ... }:
{
  # Google Drive is a user service and therefore belongs in Home Manager, but
  # the host fact remains the single broadcast activation boundary.
  flake.modules.nixos.gdrive =
    { config, lib, ... }:
    let
      host = config.my.host;
      username = if host.roles.wsl then "ssorensen" else "sam";
      tokenName = "rclone/gdrive/${lib.strings.toLower host.name}_token";
      secretFile = "${inputs.nix-secrets}/rclone/gdrive.yaml";
    in
    lib.mkIf host.features.gdrive {
      home-manager.users.${username} = { config, ... }: {
        # The personal hosts keep the age identity in Sam's SSH directory;
        # without this explicit Home Manager key source sops-nix cannot start
        # the user-level rclone mount service.
        sops.age.sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/sops_ed25519" ];
        sops.secrets = {
          "rclone/gdrive/client_id" = {
            sopsFile = secretFile;
            key = "client_id";
          };
          "rclone/gdrive/client_secret" = {
            sopsFile = secretFile;
            key = "client_secret";
          };
          ${tokenName} = {
            sopsFile = secretFile;
            key = lib.removePrefix "rclone/gdrive/" tokenName;
          };
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
              token = config.sops.secrets.${tokenName}.path;
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
