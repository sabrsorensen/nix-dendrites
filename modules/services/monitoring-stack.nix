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
      blockyMetricsPort = 4000;
      blockyPrometheusPath = "/metrics";
      blockyTargetConfigs = map (hostName: {
        targets = [ "${hostName}.${localDomain}:${toString blockyMetricsPort}" ];
        labels = {
          host = hostName;
          service = "blocky";
        };
      }) cfg.blockyTargets;
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
                color.mode = "thresholds";
                max = 100;
                min = 0;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "green";
                      value = null;
                    }
                    {
                      color = "orange";
                      value = 70;
                    }
                    {
                      color = "red";
                      value = 90;
                    }
                  ];
                };
                unit = "percent";
              };
              gridPos = {
                h = 5;
                w = 6;
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
                  expr = "100 * (1 - avg(rate(node_cpu_seconds_total{job=\"node\",mode=\"idle\"}[5m])))";
                  instant = true;
                  legendFormat = "CPU";
                  refId = "A";
                }
              ];
              title = "CPU Usage";
              type = "stat";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "thresholds";
                max = 100;
                min = 0;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "green";
                      value = null;
                    }
                    {
                      color = "orange";
                      value = 75;
                    }
                    {
                      color = "red";
                      value = 90;
                    }
                  ];
                };
                unit = "percent";
              };
              gridPos = {
                h = 5;
                w = 6;
                x = 6;
                y = 0;
              };
              id = 2;
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
                  expr = "100 * (1 - (node_memory_MemAvailable_bytes{job=\"node\"} / node_memory_MemTotal_bytes{job=\"node\"}))";
                  instant = true;
                  legendFormat = "Memory";
                  refId = "A";
                }
              ];
              title = "Memory Usage";
              type = "stat";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "thresholds";
                max = 100;
                min = 0;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "green";
                      value = null;
                    }
                    {
                      color = "orange";
                      value = 70;
                    }
                    {
                      color = "red";
                      value = 90;
                    }
                  ];
                };
                unit = "percent";
              };
              gridPos = {
                h = 5;
                w = 6;
                x = 12;
                y = 0;
              };
              id = 3;
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
                  expr = "100 * (1 - (node_filesystem_avail_bytes{job=\"node\",mountpoint=\"/\",fstype!~\"tmpfs|squashfs|overlay\"} / node_filesystem_size_bytes{job=\"node\",mountpoint=\"/\",fstype!~\"tmpfs|squashfs|overlay\"}))";
                  instant = true;
                  legendFormat = "/";
                  refId = "A";
                }
              ];
              title = "Root Disk Usage";
              type = "stat";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "thresholds";
                min = 0;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "green";
                      value = null;
                    }
                    {
                      color = "red";
                      value = 1;
                    }
                  ];
                };
                unit = "none";
              };
              gridPos = {
                h = 5;
                w = 6;
                x = 18;
                y = 0;
              };
              id = 4;
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
                  expr = "sum(node_systemd_unit_state{job=\"node\",state=\"failed\",name=~\".+\\\\.service\"})";
                  instant = true;
                  legendFormat = "failed";
                  refId = "A";
                }
              ];
              title = "Failed Services";
              type = "stat";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "palette-classic";
                unit = "short";
              };
              gridPos = {
                h = 8;
                w = 12;
                x = 0;
                y = 5;
              };
              id = 5;
              options = {
                legend = {
                  displayMode = "list";
                  placement = "bottom";
                  showLegend = true;
                };
                tooltip = {
                  mode = "single";
                  sort = "none";
                };
              };
              targets = [
                {
                  expr = "node_load1{job=\"node\"}";
                  legendFormat = "load1";
                  refId = "A";
                }
                {
                  expr = "node_load5{job=\"node\"}";
                  legendFormat = "load5";
                  refId = "B";
                }
                {
                  expr = "node_load15{job=\"node\"}";
                  legendFormat = "load15";
                  refId = "C";
                }
              ];
              title = "System Load";
              type = "timeseries";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "palette-classic";
                unit = "bytes";
              };
              gridPos = {
                h = 8;
                w = 12;
                x = 12;
                y = 5;
              };
              id = 6;
              options = {
                legend = {
                  displayMode = "list";
                  placement = "bottom";
                  showLegend = true;
                };
                tooltip = {
                  mode = "single";
                  sort = "none";
                };
              };
              targets = [
                {
                  expr = "rate(node_network_receive_bytes_total{job=\"node\",device=~\"^(en|eth|end|wl|ww)[a-zA-Z0-9._-]*$\"}[5m])";
                  legendFormat = "{{device}} rx";
                  refId = "A";
                }
                {
                  expr = "rate(node_network_transmit_bytes_total{job=\"node\",device=~\"^(en|eth|end|wl|ww)[a-zA-Z0-9._-]*$\"}[5m])";
                  legendFormat = "{{device}} tx";
                  refId = "B";
                }
              ];
              title = "Network Throughput";
              type = "timeseries";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "thresholds";
                min = 0;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "green";
                      value = null;
                    }
                  ];
                };
                unit = "none";
              };
              gridPos = {
                h = 6;
                w = 8;
                x = 0;
                y = 13;
              };
              id = 7;
              options = {
                colorMode = "value";
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
                  expr = "sum(node_systemd_unit_state{job=\"node\",state=\"active\",name=~\".+\\\\.service\"})";
                  instant = true;
                  legendFormat = "active";
                  refId = "A";
                }
              ];
              title = "Active Services";
              type = "stat";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "palette-classic";
                decimals = 1;
                unit = "percent";
              };
              gridPos = {
                h = 6;
                w = 16;
                x = 8;
                y = 13;
              };
              id = 8;
              options = {
                legend = {
                  displayMode = "table";
                  placement = "right";
                  showLegend = true;
                };
                tooltip = {
                  mode = "single";
                  sort = "none";
                };
              };
              targets = [
                {
                  expr = "100 * (1 - (node_filesystem_avail_bytes{job=\"node\",mountpoint!~\"^/(run|sys|proc)($|/)|^/var/lib/(docker|containers)($|/)|^/nix/store($|/)\",fstype!~\"tmpfs|squashfs|overlay|nsfs|fuse.lxcfs|tracefs|fuse.mergerfs\"} / node_filesystem_size_bytes{job=\"node\",mountpoint!~\"^/(run|sys|proc)($|/)|^/var/lib/(docker|containers)($|/)|^/nix/store($|/)\",fstype!~\"tmpfs|squashfs|overlay|nsfs|fuse.lxcfs|tracefs|fuse.mergerfs\"}))";
                  legendFormat = "{{mountpoint}}";
                  refId = "A";
                }
              ];
              title = "Filesystem Usage";
              type = "timeseries";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "palette-classic";
                decimals = 1;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "green";
                      value = null;
                    }
                    {
                      color = "orange";
                      value = 70;
                    }
                    {
                      color = "red";
                      value = 85;
                    }
                  ];
                };
                unit = "celsius";
              };
              gridPos = {
                h = 8;
                w = 24;
                x = 0;
                y = 19;
              };
              id = 9;
              options = {
                legend = {
                  displayMode = "table";
                  placement = "right";
                  showLegend = true;
                };
                tooltip = {
                  mode = "multi";
                  sort = "desc";
                };
              };
              targets = [
                {
                  expr = "node_hwmon_temp_celsius{job=\"node\",chip=~\".*(coretemp|k10temp|zenpower|cpu|jc42|spd|dimm|mem).*\"}";
                  legendFormat = "{{chip}} {{sensor}}";
                  refId = "A";
                }
                {
                  expr = "smartctl_device_temperature{job=\"smartctl\"}";
                  legendFormat = "{{device}} drive";
                  refId = "B";
                }
              ];
              title = "Hardware Temperatures";
              type = "timeseries";
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
          title = "Atlas Host Overview";
          uid = "atlas-host-overview";
          version = 1;
        }
      );
      grafanaBlockyDashboard = pkgs.writeText "grafana-blocky-overview.json" (
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
                color.mode = "palette-classic";
                unit = "reqps";
              };
              gridPos = {
                h = 8;
                w = 12;
                x = 0;
                y = 0;
              };
              id = 1;
              options = {
                legend = {
                  displayMode = "list";
                  placement = "bottom";
                  showLegend = true;
                };
                tooltip = {
                  mode = "single";
                  sort = "desc";
                };
              };
              targets = [
                {
                  expr = "sum by (host) (rate(blocky_query_total{job=\"blocky\"}[$__rate_interval]))";
                  legendFormat = "{{host}}";
                  refId = "A";
                }
              ];
              title = "DNS Query Rate";
              type = "timeseries";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "thresholds";
                max = 1;
                min = 0;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "red";
                      value = null;
                    }
                    {
                      color = "orange";
                      value = 0.25;
                    }
                    {
                      color = "green";
                      value = 0.5;
                    }
                  ];
                };
                unit = "percentunit";
              };
              gridPos = {
                h = 8;
                w = 6;
                x = 12;
                y = 0;
              };
              id = 2;
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
                  expr = "sum(increase(blocky_cache_hits_total{job=\"blocky\"}[$__range])) / (sum(increase(blocky_cache_hits_total{job=\"blocky\"}[$__range])) + sum(increase(blocky_cache_misses_total{job=\"blocky\"}[$__range])))";
                  instant = true;
                  refId = "A";
                }
              ];
              title = "Cache Hit Ratio";
              type = "stat";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "thresholds";
                max = 1;
                min = 0;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "green";
                      value = null;
                    }
                    {
                      color = "orange";
                      value = 0.1;
                    }
                    {
                      color = "red";
                      value = 0.25;
                    }
                  ];
                };
                unit = "percentunit";
              };
              gridPos = {
                h = 8;
                w = 6;
                x = 18;
                y = 0;
              };
              id = 3;
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
                  expr = "sum(increase(blocky_response_total{job=\"blocky\",response_type=\"BLOCKED\"}[$__range])) / sum(increase(blocky_query_total{job=\"blocky\"}[$__range]))";
                  instant = true;
                  refId = "A";
                }
              ];
              title = "Blocked Query Ratio";
              type = "stat";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "palette-classic";
                unit = "s";
              };
              gridPos = {
                h = 8;
                w = 12;
                x = 0;
                y = 8;
              };
              id = 4;
              options = {
                legend = {
                  displayMode = "list";
                  placement = "bottom";
                  showLegend = true;
                };
                tooltip = {
                  mode = "single";
                  sort = "desc";
                };
              };
              targets = [
                {
                  expr = "((sum by (host) (rate(blocky_request_duration_seconds_sum{job=\"blocky\"}[$__rate_interval])) / sum by (host) (rate(blocky_request_duration_seconds_count{job=\"blocky\"}[$__rate_interval])))) or ((sum by (host) (rate(blocky_request_duration_ms_sum{job=\"blocky\"}[$__rate_interval])) / sum by (host) (rate(blocky_request_duration_ms_count{job=\"blocky\"}[$__rate_interval])) / 1000))";
                  legendFormat = "{{host}}";
                  refId = "A";
                }
              ];
              title = "Average Response Time";
              type = "timeseries";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "palette-classic";
                unit = "reqps";
              };
              gridPos = {
                h = 8;
                w = 12;
                x = 12;
                y = 8;
              };
              id = 5;
              options = {
                legend = {
                  displayMode = "table";
                  placement = "right";
                  showLegend = true;
                };
                tooltip = {
                  mode = "multi";
                  sort = "desc";
                };
              };
              targets = [
                {
                  expr = "sum by (host, response_type) (rate(blocky_response_total{job=\"blocky\"}[$__rate_interval]))";
                  legendFormat = "{{host}} {{response_type}}";
                  refId = "A";
                }
              ];
              title = "Responses by Type";
              type = "timeseries";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              fieldConfig.defaults = {
                color.mode = "palette-classic";
                unit = "none";
              };
              gridPos = {
                h = 8;
                w = 24;
                x = 0;
                y = 16;
              };
              id = 6;
              options = {
                legend = {
                  displayMode = "table";
                  placement = "right";
                  showLegend = true;
                };
                tooltip = {
                  mode = "multi";
                  sort = "desc";
                };
              };
              targets = [
                {
                  expr = "sum by (host, question_type) (rate(blocky_query_total{job=\"blocky\"}[$__rate_interval]))";
                  legendFormat = "{{host}} {{question_type}}";
                  refId = "A";
                }
              ];
              title = "Queries by Type";
              type = "timeseries";
            }
          ];
          refresh = "30s";
          schemaVersion = 39;
          tags = [
            "blocky"
            "dns"
            "prometheus"
          ];
          templating.list = [ ];
          time = {
            from = "now-6h";
            to = "now";
          };
          timezone = "browser";
          title = "Blocky DNS Overview";
          uid = "blocky-dns-overview";
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

        blockyTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Hostnames whose Blocky Prometheus endpoints should be scraped by Atlas.";
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
                    {
                      name = "blocky-dns-overview.json";
                      path = grafanaBlockyDashboard;
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
          ++ lib.optionals (cfg.blockyTargets != [ ]) [
            {
              job_name = "blocky";
              metrics_path = blockyPrometheusPath;
              static_configs = blockyTargetConfigs;
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
