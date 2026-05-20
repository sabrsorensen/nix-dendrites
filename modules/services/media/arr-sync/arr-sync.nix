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
  {
    sops.secrets = {
      arr-sync_env = {
        owner = "sam";
        group = "sam";
        mode = "0400";
        format = "dotenv";
        sopsFile = "${inputs.nix-secrets}/env_files/arr-sync.env";
        key = "";
      };
    };
    virtualisation.oci-containers.containers."arr-sync" = {
      image = "ghcr.io/sabrsorensen/arr-sync-webhook";
      environmentFiles = [
        config.sops.secrets.arr-sync_env.path
      ];
      ports = [
        "127.0.0.1:3000:3000/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=host"
      ];
    };
  };
}