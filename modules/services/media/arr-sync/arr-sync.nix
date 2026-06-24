{
  inputs,
  ...
}:
{
  flake.modules.nixos.arr-sync =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.services."arr-sync";
      serviceName = "arr-sync";
    in
    {
      options.my.services."arr-sync" = {
        enable = lib.mkEnableOption "Arr Sync webhook service";

        image = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/sabrsorensen/arr-sync-webhook";
        };
      };

      config = lib.mkIf cfg.enable {
        users.groups.${serviceName} = { };
        users.users.${serviceName} = {
          isSystemUser = true;
          group = serviceName;
        };
        sops.secrets = {
          arr-sync_env = {
            owner = serviceName;
            group = serviceName;
            mode = "0400";
            format = "dotenv";
            sopsFile = "${inputs.nix-secrets}/env_files/arr-sync.env";
            key = "";
          };
        };
        virtualisation.oci-containers.containers.${serviceName} = {
          image = cfg.image;
          login = {
            registry = "ghcr.io";
            username = "sabrsorensen";
            passwordFile = config.sops.secrets.ghcr_token.path;
          };
          environmentFiles = [
            config.sops.secrets.arr-sync_env.path
          ];
          log-driver = "journald";
          extraOptions = [
            "--network=host"
          ];
        };
      };
    };
}
