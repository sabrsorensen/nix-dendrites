{
  flake.modules.nixos.monitoring-stack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.monitoring;
      localDomain = config.systemConstants.domain;
      grafanaDomain = "${cfg.grafanaHostName}.${localDomain}";
      prometheusDomain = "${cfg.prometheusHostName}.${localDomain}";
      grafanaVirtualHost = "${cfg.grafanaHostName}.{$DOMAIN}";
      prometheusVirtualHost = "${cfg.prometheusHostName}.{$DOMAIN}";
      grafanaRootUrl = "https://${grafanaDomain}/";
      grafanaDatasourceUid = "prometheus";
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
      grafanaDashboard = pkgs.writeText "grafana-atlas-host-overview.json" (
        builtins.toJSON {
          annotations.list = [ ];
          editable = true;
          id = null;
          panels = [
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                min = 0;
                thresholds.mode = "absolute";
                thresholds.steps = [
                  {
                    color = "red";
                    value = null;
                  }
                  {
                    color = "green";
                    value = 1;
                  }
                ];
                unit = "short";
              };
              gridPos = {
                h = 5;
                w = 8;
                x = 0;
                y = 0;
              };
              id = 1;
              options = {
                colorMode = "background";
                graphMode = "none";
                justifyMode = "center";
                orientation = "auto";
                reduceOptions = {
                  calcs = [ "lastNotNull" ];
                  fields = "";
                  values = false;
                };
                textMode = "value";
              };
              targets = [
                {
                  expr = "sum(up{job=\"node\"})";
                  instant = true;
                  refId = "A";
                }
              ];
              title = "Node Exporter Up";
              type = "stat";
            }
          ];
          refresh = "30s";
          schemaVersion = 39;
          tags = [
            "atlas"
            "host"
            "prometheus"
          ];
          templating.list = [ ];
          time = {
            from = "now-6h";
            to = "now";
          };
          timezone = "browser";
          title = "Atlas Host Overview (Minimal)";
          uid = "atlas-host-overview";
          version = 1;
        }
      );
    in
    {
      options.my.services.monitoring = {
        enable = lib.mkEnableOption "Prometheus and Grafana monitoring stack";

        grafanaHostName = lib.mkOption {
          type = lib.types.str;
          default = "grafana";
        };

        prometheusHostName = lib.mkOption {
          type = lib.types.str;
          default = "prometheus";
        };

        basicAuthUser = lib.mkOption {
          type = lib.types.str;
          default = "sorenssa";
        };

        basicAuthPasswordEnvVar = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Caddy environment variable name used for optional basic auth.";
        };

        enableSmartctlExporter = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        my.localDns.records = [
          { hostname = cfg.grafanaHostName; }
          { hostname = cfg.prometheusHostName; }
        ];

        sops.secrets.grafana_secret_key = {
          owner = "grafana";
          group = "grafana";
          mode = "0400";
        };

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
          provision = {
            enable = true;
            datasources.settings = {
              apiVersion = 1;
              datasources = [
                {
                  access = "proxy";
                  editable = false;
                  isDefault = true;
                  name = "Prometheus";
                  type = "prometheus";
                  uid = grafanaDatasourceUid;
                  url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
                }
              ];
            };
            dashboards.settings = {
              apiVersion = 1;
              providers = [
                {
                  disableDeletion = false;
                  folder = "Infrastructure";
                  name = "atlas";
                  options.path = pkgs.linkFarm "grafana-dashboards" [
                    {
                      name = "atlas-host-overview.json";
                      path = grafanaDashboard;
                    }
                  ];
                  orgId = 1;
                  type = "file";
                }
              ];
            };
          };
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
        };

        services.prometheus = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 9090;
          webExternalUrl = "https://${prometheusDomain}";
          exporters = {
            node = {
              enable = true;
              enabledCollectors = [
                "hwmon"
                "systemd"
              ];
              listenAddress = "127.0.0.1";
            };
            smartctl = {
              enable = cfg.enableSmartctlExporter;
              listenAddress = "127.0.0.1";
            };
          };
          scrapeConfigs = [
            {
              job_name = "prometheus";
              static_configs = [
                {
                  targets = [ "127.0.0.1:${toString config.services.prometheus.port}" ];
                }
              ];
            }
            {
              job_name = "node";
              static_configs = [
                {
                  targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
                }
              ];
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
      };
    };
}
