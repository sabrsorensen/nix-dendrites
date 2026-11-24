{ inputs, ... }:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
in
{
  flake.modules.nixos.smb-media =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.host.features.smbMedia =
        lib.mkEnableOption "AtlasUponRaiden's Samba `media` share mounted at /mnt/videos";

      config = lib.mkIf config.my.host.features.smbMedia {
        environment.systemPackages = [ pkgs.cifs-utils ];

        # A multi-line YAML string in nix-secrets/secrets.yaml:
        #   smb_media_credentials: |
        #     username=sam
        #     password=...
        sops.secrets.smb_media_credentials = {
          owner = "root";
          group = "root";
          mode = "0400";
          sopsFile = "${inputs.nix-secrets}/secrets.yaml";
        };

        fileSystems."/mnt/media" = {
          device = "//${network.atlasuponraiden}/media";
          fsType = "cifs";
          options = [
            "credentials=${config.sops.secrets.smb_media_credentials.path}"
            "uid=sam"
            "gid=sam"
            # Mount on first access so boot doesn't hang if the server is down.
            "x-systemd.automount"
            "noauto"
            "x-systemd.idle-timeout=60"
            "x-systemd.mount-timeout=10s"
            "_netdev"
          ];
        };
      };
    };
}
