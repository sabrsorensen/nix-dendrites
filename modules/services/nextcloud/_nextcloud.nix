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
    package = pkgs.nextcloud34;
    hostName = nextcloudHost;
    https = false;
    datadir = cfg.dataDir;
    database.createLocally = true;
    config = {
      adminuser = "sam";
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
      dbtype = "pgsql";
    };
    extraApps = {
      inherit (pkgs.nextcloud34Packages.apps) richdocuments;
    };
    # Retain the App Store for non-core apps while pinning the office
    # integration to the Nextcloud version selected above.
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
  # a manually changed office URL.
  systemd.services.nextcloud-richdocuments = {
    description = "Configure Nextcloud Richdocuments for Collabora Online";
    wantedBy = [ "multi-user.target" ];
    after = [
      "caddy.service"
      "coolwsd.service"
      "nextcloud-setup.service"
    ];
    requires = [
      "coolwsd.service"
      "nextcloud-setup.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "nextcloud";
    };
    script = ''
      ${lib.getExe config.services.nextcloud.occ} config:app:set --value ${lib.escapeShellArg "https://${collaboraHost}"} richdocuments wopi_url
      ${lib.getExe config.services.nextcloud.occ} config:app:set --value ${lib.escapeShellArg "https://${collaboraHost}"} richdocuments public_wopi_url
      ${lib.getExe config.services.nextcloud.occ} richdocuments:activate-config
    '';
  };
}
