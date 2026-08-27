{
  config,
  cfg,
  localAddr,
  mediaCfg,
  serviceName,
  ...
}:
{
  users.groups.${serviceName} = { };
  users.users.${serviceName} = {
    isSystemUser = true;
    group = serviceName;
  };
  my.caddy.apexRoutes = [
    ''
      redir /${cfg.pathSegment} /${cfg.pathSegment}/
      route /${cfg.pathSegment}/* {
        filter {
          content_type text/html.*
          search_pattern </head>
          replacement "<link rel='stylesheet' type='text/css' href='https://theme-park.dev/css/base/${serviceName}/aquamarine.css'></head>"
        }
        reverse_proxy /${cfg.pathSegment}/* ${localAddr} {
          header_up -Accept-Encoding
        }
      }
    ''
  ];
  virtualisation.oci-containers.containers.${serviceName} = {
    image = "ghcr.io/autobrr/autobrr:latest";
    autoStart = true;
    environment = {
      "AUTOBRR__HOST" = "127.0.0.1";
      "AUTOBRR__PORT" = "7474";
      "AUTOBRR__BASE_URL" = "/${cfg.pathSegment}/";
      "TZ" = config.time.timeZone;
    };
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "${mediaCfg.configRoot}/${serviceName}:/config"
    ];
    labels."com.centurylinklabs.watchtower.enable" = "true";
    log-driver = "journald";
    extraOptions = [
      "--network=host"
      "--health-cmd=curl --fail http://localhost:7474/api/healthz/liveness || exit 1"
      "--health-interval=10s"
      "--health-retries=5"
      "--health-start-period=15s"
      "--health-timeout=10s"
    ];
  };
}
