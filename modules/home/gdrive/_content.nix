{
  secretFile,
  tokenName,
}:
{ config, lib, ... }:
{
  # The personal hosts keep the age identity in Sam's SSH directory; without
  # this Home Manager key source sops-nix cannot start the rclone mount.
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
}
