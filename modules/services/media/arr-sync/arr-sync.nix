{
  inputs,
  ...
}:
{
  flake.modules.nixos.arr-sync =
    {
      config,
      ...
    }:
    let
      localAddr = "127.0.0.1:3000";
      serviceName = "arr-sync";
    in
    {
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
        image = "ghcr.io/sabrsorensen/arr-sync-webhook";
        login = {
          registry = "ghcr.io";
          username = "sabrsorensen";
          passwordFile = config.sops.secrets.ghcr_token.path;
        };
        environmentFiles = [
          config.sops.secrets.arr-sync_env.path
        ];
        ports = [
          "${localAddr}:3000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network=host"
        ];
      };
    };
}
