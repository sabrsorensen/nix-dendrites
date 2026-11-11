{
  config,
  lib,
  pkgs,
  secretFile,
  tokenName,
  ...
}:
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
  # A user unit cannot order itself after the system network-online.target, so
  # at login rclone races NetworkManager and dies on "lookup
  # oauth2.googleapis.com: no such host" until a restart happens to land after
  # DNS is up. Wait (bounded, inside the default start timeout) for resolution
  # instead; on timeout rclone still runs and Restart=on-failure takes over.
  systemd.user.services."rclone-mount:@gdrive".Service.ExecStartPre = lib.mkForce [
    "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/gdrive"}"
    "${pkgs.writeShellScript "rclone-gdrive-wait-dns" ''
      for _ in $(${pkgs.coreutils}/bin/seq 60); do
        ${pkgs.getent}/bin/getent hosts oauth2.googleapis.com >/dev/null && exit 0
        ${pkgs.coreutils}/bin/sleep 1
      done
      echo "DNS for oauth2.googleapis.com still unavailable after 60s" >&2
    ''}"
  ];
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
