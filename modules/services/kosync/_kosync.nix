{
  config,
  lib,
  cfg,
  ...
}:
let
  dataDir = "${config.my.media.configRoot}/kosync";
in
{
  assertions = [
    {
      assertion = config.my.host.features.podman;
      message = "services.kosync runs the upstream koreader/kosync image and requires features.podman.";
    }
  ];

  my.localDns.records = [ { hostname = cfg.hostName; } ];
  my.caddy.virtualHosts."${cfg.hostName}.{$DOMAIN}".routes = [
    ''
      reverse_proxy /* 127.0.0.1:${toString cfg.port}
    ''
  ];

  # Redis and the OpenResty app both run as root inside the image (no USER
  # directive), so root-owned host directories are fine.
  systemd.tmpfiles.settings."10-kosync" = {
    "${dataDir}/redis".d.mode = "0700";
    "${dataDir}/logs".d.mode = "0755";
  };

  virtualisation.oci-containers.containers.kosync = {
    image = "docker.io/koreader/kosync:latest";
    autoStart = true;
    pull = "newer";
    # The image defaults ENABLE_USER_REGISTRATION=true; anything other than
    # "true"/"1" swaps POST /users/create for a "registration disabled" handler.
    environment.ENABLE_USER_REGISTRATION = lib.boolToString cfg.allowRegistration;
    volumes = [
      "${dataDir}/redis:/var/lib/redis:rw"
      "${dataDir}/logs:/app/koreader-sync-server/logs:rw"
    ];
    # 17200 is the image's plain-HTTP listener (7200 is HTTPS with a
    # self-signed cert); Caddy terminates TLS.
    ports = [ "127.0.0.1:${toString cfg.port}:17200/tcp" ];
    labels."com.centurylinklabs.watchtower.enable" = "true";
    log-driver = "journald";
  };
}
