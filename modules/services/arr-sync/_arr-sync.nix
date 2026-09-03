{
  cfg,
  config,
  inputs,
  serviceName,
  ...
}:
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
      ''--health-cmd=node -e "require('http').get('http://localhost:3000/', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"''
      "--health-interval=10s"
      "--health-retries=5"
      "--health-start-period=15s"
      "--health-timeout=10s"
    ];
  };
}
