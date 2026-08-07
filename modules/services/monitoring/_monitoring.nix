{
  config,
  lib,
  pkgs,
  cfg,
  domain,
  grafanaBlockyDashboard,
  grafanaDashboard,
  grafanaRpiServicesDashboard,
  secretsFile,
  ...
}:
let
  grafanaDomain = "${cfg.grafanaHostName}.${domain}";
  prometheusDomain = "${cfg.prometheusHostName}.${domain}";
  grafanaVirtualHost = "${cfg.grafanaHostName}.{$DOMAIN}";
  prometheusVirtualHost = "${cfg.prometheusHostName}.{$DOMAIN}";
  grafanaRootUrl = "https://${grafanaDomain}/";
  maybeBasicAuthLines =
    routePrefix:
    lib.optionals (cfg.basicAuthPasswordEnvVar != null) [
      "${routePrefix}basic_auth /* {"
      ("${routePrefix}    ${cfg.basicAuthUser} {$" + cfg.basicAuthPasswordEnvVar + "}")
      "${routePrefix}}"
    ];
  mkReverseProxyRoute =
    {
      listenAddress,
      port,
    }:
    lib.concatStringsSep "\n" (
      maybeBasicAuthLines "  "
      ++ [
        "  reverse_proxy /* ${listenAddress}:${toString port}"
      ]
    );
in
{
  sops.secrets.grafana_secret_key = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
    sopsFile = secretsFile;
  };
  my.localDns.records = [
    { hostname = cfg.grafanaHostName; }
    { hostname = cfg.prometheusHostName; }
  ];
  my.caddy.virtualHosts = {
    "${grafanaVirtualHost}".routes = [
      (mkReverseProxyRoute {
        listenAddress = config.services.grafana.settings.server.http_addr;
        port = config.services.grafana.settings.server.http_port;
      })
    ];
    "${prometheusVirtualHost}".routes = [
      (mkReverseProxyRoute {
        listenAddress = config.services.prometheus.listenAddress;
        port = config.services.prometheus.port;
      })
    ];
  };
  services.grafana = {
    enable = true;
    settings = {
      auth.disable_login_form = true;
      "auth.anonymous" = {
        enabled = true;
        org_name = "Main Org.";
        org_role = "Viewer";
      };
      security = {
        disable_initial_admin_creation = true;
        secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
      };
      server = {
        domain = grafanaDomain;
        enforce_domain = true;
        http_addr = "127.0.0.1";
        http_port = 3030;
        root_url = grafanaRootUrl;
      };
      users.default_theme = "system";
    };
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            uid = "prometheus";
            access = "proxy";
            isDefault = true;
            editable = false;
            url = "http://127.0.0.1:9090";
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "infrastructure";
            folder = "Infrastructure";
            type = "file";
            disableDeletion = false;
            editable = true;
            options.path = pkgs.linkFarm "grafana-dashboards" [
              {
                name = "atlas-host-overview.json";
                path = grafanaDashboard;
              }
              {
                name = "blocky-dns-overview.json";
                path = grafanaBlockyDashboard;
              }
              {
                name = "naboo-nevarro-overview.json";
                path = grafanaRpiServicesDashboard;
              }
            ];
          }
        ];
      };
    };
  };
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    webExternalUrl = "https://${prometheusDomain}";
    exporters = {
      node = {
        enable = true;
        listenAddress = "127.0.0.1";
        enabledCollectors = [
          "hwmon"
          "systemd"
        ];
      };
      smartctl = {
        enable = cfg.enableSmartctlExporter;
        listenAddress = "127.0.0.1";
      };
    };
    scrapeConfigs = [
      {
        job_name = "prometheus";
        static_configs = [ { targets = [ "127.0.0.1:9090" ]; } ];
      }
      {
        job_name = "node";
        static_configs = [
          { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
        ];
      }
    ]
    ++ lib.optionals (cfg.nodeTargets != [ ]) [
      {
        job_name = "remote-node";
        static_configs = map (host: {
          targets = [ "${host}.${domain}:9100" ];
          labels.host = host;
        }) cfg.nodeTargets;
      }
    ]
    ++ lib.optionals (cfg.blockyTargets != [ ]) [
      {
        job_name = "blocky";
        metrics_path = "/metrics";
        static_configs = map (host: {
          targets = [ "${host}.${domain}:4000" ];
          labels = {
            inherit host;
            service = "blocky";
          };
        }) cfg.blockyTargets;
      }
    ]
    ++ lib.optionals (cfg.smartctlTargets != [ ]) [
      {
        job_name = "remote-smartctl";
        static_configs = map (host: {
          targets = [ "${host}.${domain}:9633" ];
          labels.host = host;
        }) cfg.smartctlTargets;
      }
    ]
    ++ lib.optional cfg.enableSmartctlExporter {
      job_name = "smartctl";
      static_configs = [
        {
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}" ];
        }
      ];
    };
  };
}
