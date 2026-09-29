{
  config,
  cfg,
  domain,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  nextcloudHost = "${cfg.hostName}.${domain}";
  collaboraHost = "${cfg.collaboraHostName}.${domain}";
  nextcloudPort = 8090;
in
{
  sops.secrets.nextcloud_admin_password = {
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0400";
    sopsFile = "${inputs.nix-secrets}/secrets.yaml";
  };

  my.localDns.records = [
    { hostname = cfg.hostName; }
    { hostname = cfg.collaboraHostName; }
  ];

  my.caddy.virtualHosts = {
    "${nextcloudHost}".routes = [
      ''
        reverse_proxy /* 127.0.0.1:${toString nextcloudPort}
      ''
    ];
    "${collaboraHost}".routes = [
      ''
        reverse_proxy /* 127.0.0.1:${toString config.services.collabora-online.port}
      ''
    ];
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    hostName = nextcloudHost;
    https = false;
    datadir = cfg.dataDir;
    database.createLocally = true;
    config = {
      adminuser = "sorenssa";
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
      dbtype = "pgsql";
    };
    # The App Store owns every non-core app, including richdocuments.  Don't
    # also pin a store app via extraApps: `occ upgrade` then installs the newer
    # store copy beside the Nix one, PHP fatals on the duplicate autoloader,
    # and nextcloud-setup leaves the instance stuck in maintenance mode.
    appstoreEnable = true;
    settings = {
      overwrite.cli.url = "https://${nextcloudHost}";
      overwritehost = nextcloudHost;
      overwriteprotocol = "https";
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];
    };
  };

  # The NixOS Nextcloud module supplies the hardened NGINX/PHP-FPM frontend.
  # Caddy owns public TLS, so bind that internal frontend only to loopback.
  services.nginx.virtualHosts.${nextcloudHost}.listen = lib.mkForce [
    {
      addr = "127.0.0.1";
      port = nextcloudPort;
    }
  ];

  services.collabora-online = {
    enable = true;
    settings = {
      net = {
        proto = "IPv4";
        listen = "loopback";
      };
      server_name = collaboraHost;
      ssl = {
        enable = false;
        termination = true;
      };
    };
    aliasGroups = [
      {
        host = "https://${nextcloudHost}:443";
        aliases = [ "https://${nextcloudHost}" ];
      }
    ];
  };

  # Keep the richdocuments connection declarative.  These commands are
  # idempotent, so running them after either service is restarted also repairs
  # a manually changed office URL or a removed app.
  systemd.services.nextcloud-richdocuments = {
    description = "Configure Nextcloud Richdocuments for Collabora Online";
    wantedBy = [ "multi-user.target" ];
    after = [
      "caddy.service"
      "coolwsd.service"
      "network-online.target"
      "nextcloud-setup.service"
    ];
    wants = [ "network-online.target" ];
    requires = [
      "coolwsd.service"
      "nextcloud-setup.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
    };
    script = ''
      if ! ${lib.getExe config.services.nextcloud.occ} app:getpath richdocuments >/dev/null; then
        ${lib.getExe config.services.nextcloud.occ} app:install --keep-disabled richdocuments
      fi
      ${lib.getExe config.services.nextcloud.occ} app:enable richdocuments
      ${lib.getExe config.services.nextcloud.occ} config:app:set --value ${lib.escapeShellArg "https://${collaboraHost}"} richdocuments wopi_url
      ${lib.getExe config.services.nextcloud.occ} config:app:set --value ${lib.escapeShellArg "https://${collaboraHost}"} richdocuments public_wopi_url
      ${lib.getExe config.services.nextcloud.occ} richdocuments:activate-config
    '';
  };
}
