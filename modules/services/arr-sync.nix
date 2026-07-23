{ inputs, ... }:
{
  flake.modules.nixos.arr-sync =
    { config, lib, ... }:
    let
      cfg = config.my.arrSync;
    in
    {
      options.my.arrSync.image = lib.mkOption {
        type = lib.types.str;
        default = "ghcr.io/sabrsorensen/arr-sync-webhook";
        description = "Container image for the Arr Sync webhook service.";
      };

      config = lib.mkIf config.my.host.services.arrSync {
        users.groups.arr-sync = { };
        users.users.arr-sync = {
          isSystemUser = true;
          group = "arr-sync";
        };
        sops.secrets.arr-sync_env = {
          owner = "arr-sync";
          group = "arr-sync";
          mode = "0400";
          format = "dotenv";
          sopsFile = "${inputs.nix-secrets}/env_files/arr-sync.env";
          key = "";
        };
        virtualisation.oci-containers.containers.arr-sync = {
          image = cfg.image;
          login = {
            registry = "ghcr.io";
            username = "sabrsorensen";
            passwordFile = config.sops.secrets.ghcr_token.path;
          };
          environmentFiles = [ config.sops.secrets.arr-sync_env.path ];
          log-driver = "journald";
          extraOptions = [ "--network=host" ];
        };
      };
    };
}
