{ inputs, ... }:
let
  domain = builtins.replaceStrings [ "\n" ] [ "" ] (
    builtins.readFile "${inputs.nix-secrets}/domain.txt"
  );
in
{
  flake.modules.nixos.monitoring =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.monitoring;
      grafanaDatasourceUid = "prometheus";
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
                  expr = "max by (name) (node_systemd_unit_state{job=\"node\",state=\"active\",name=~\".+\\\\.service\"})";
                  format = "table";
                  instant = true;
                  legendFormat = "{{name}}";
                  refId = "A";
                }
              ];
              title = "Active Service Units";
              type = "table";
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
                  expr = "100 * (1 - (node_filesystem_avail_bytes{job=\"node\",mountpoint!~\"^/(run|sys|proc)($|/)|^/var/run($|/)|^/var/lib/(docker|containers)($|/)|^/nix/store($|/)\",fstype!~\"tmpfs|squashfs|overlay|nsfs|fuse.lxcfs|tracefs|fuse.mergerfs\"} / node_filesystem_size_bytes{job=\"node\",mountpoint!~\"^/(run|sys|proc)($|/)|^/var/run($|/)|^/var/lib/(docker|containers)($|/)|^/nix/store($|/)\",fstype!~\"tmpfs|squashfs|overlay|nsfs|fuse.lxcfs|tracefs|fuse.mergerfs\"}))";
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
                  expr = "node_hwmon_temp_celsius{job=\"node\",chip=\"platform_coretemp_0\",sensor=\"temp1\"}";
                  legendFormat = "CPU temp";
                  refId = "A";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"node\",chip=\"nvme_nvme0\",sensor=\"temp1\"}";
                  legendFormat = "nvme0 temp";
                  refId = "B";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"node\",chip=\"nvme_nvme1\",sensor=\"temp1\"}";
                  legendFormat = "nvme1 temp";
                  refId = "C";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"node\",chip=~\".*(coretemp|k10temp|zenpower|cpu).*\",sensor=~\"(Package id 0|Tctl|Tdie|temp1)\",chip!=\"platform_coretemp_0\"}";
                  legendFormat = "{{chip}} {{sensor}}";
                  refId = "D";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"node\",chip=~\".*(jc42|spd|dimm|mem).*\"}";
                  legendFormat = "{{chip}} {{sensor}}";
                  refId = "E";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"node\",chip=~\".*nvme.*\",chip!~\"nvme_nvme[01]\"}";
                  legendFormat = "{{chip}} {{sensor}}";
                  refId = "F";
                }
                {
                  expr = "smartctl_device_temperature{job=\"smartctl\"}";
                  legendFormat = "{{device}}";
                  refId = "G";
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
                h = 5;
                w = 6;
                x = 0;
                y = 0;
              };
              id = 1;
              options = {
                colorMode = "background";
                graphMode = "area";
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
                h = 5;
                w = 6;
                x = 6;
                y = 0;
              };
              id = 2;
              options = {
                colorMode = "background";
                graphMode = "area";
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
                  expr = "(sum(rate(blocky_request_duration_seconds_sum{job=\"blocky\"}[$__rate_interval])) / sum(rate(blocky_request_duration_seconds_count{job=\"blocky\"}[$__rate_interval]))) or (sum(rate(blocky_request_duration_ms_sum{job=\"blocky\"}[$__rate_interval])) / sum(rate(blocky_request_duration_ms_count{job=\"blocky\"}[$__rate_interval])) / 1000)";
                  instant = true;
                  refId = "A";
                }
              ];
              title = "Average Response Time";
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
                      color = "red";
                      value = null;
                    }
                    {
                      color = "green";
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
                  expr = "sum(blocky_blocking_enabled{job=\"blocky\"})";
                  instant = true;
                  refId = "A";
                }
              ];
              title = "Blocking Enabled";
              type = "stat";
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
                x = 0;
                y = 5;
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
                  expr = "sum by (response_type) (rate(blocky_response_total{job=\"blocky\"}[$__rate_interval]))";
                  legendFormat = "{{response_type}}";
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
                w = 12;
                x = 12;
                y = 5;
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
                  expr = "sum(rate(blocky_query_total{job=\"blocky\"}[$__rate_interval]))";
                  legendFormat = "queries";
                  refId = "A";
                }
              ];
              title = "DNS Query Rate";
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
      grafanaRpiServicesDashboard = pkgs.writeText "grafana-rpi-services-overview.json" (
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
              title = "Blocky Query Rate";
              type = "timeseries";
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
                  expr = "100 * (1 - avg by (host) (rate(node_cpu_seconds_total{job=\"remote-node\",mode=\"idle\"}[5m])))";
                  instant = true;
                  legendFormat = "{{host}}";
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
                  expr = "100 * (1 - (node_memory_MemAvailable_bytes{job=\"remote-node\"} / node_memory_MemTotal_bytes{job=\"remote-node\"}))";
                  instant = true;
                  legendFormat = "{{host}}";
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
                color.mode = "palette-classic";
                unit = "bytes";
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
                  displayMode = "table";
                  placement = "right";
                  showLegend = true;
                };
                tooltip = {
                  mode = "single";
                  sort = "desc";
                };
              };
              targets = [
                {
                  expr = "rate(node_network_receive_bytes_total{job=\"remote-node\",device=~\"^(en|eth|end|wl|ww)[a-zA-Z0-9._-]*$\"}[5m])";
                  legendFormat = "{{host}} {{device}} rx";
                  refId = "A";
                }
                {
                  expr = "rate(node_network_transmit_bytes_total{job=\"remote-node\",device=~\"^(en|eth|end|wl|ww)[a-zA-Z0-9._-]*$\"}[5m])";
                  legendFormat = "{{host}} {{device}} tx";
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
                color.mode = "palette-classic";
                unit = "percent";
                decimals = 1;
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
                  mode = "single";
                  sort = "none";
                };
              };
              targets = [
                {
                  expr = "100 * (1 - (node_filesystem_avail_bytes{job=\"remote-node\",mountpoint!~\"^/(run|sys|proc)($|/)|^/var/run($|/)|^/var/lib/(docker|containers)($|/)|^/nix/store($|/)\",fstype!~\"tmpfs|squashfs|overlay|nsfs|fuse.lxcfs|tracefs|fuse.mergerfs\"} / node_filesystem_size_bytes{job=\"remote-node\",mountpoint!~\"^/(run|sys|proc)($|/)|^/var/run($|/)|^/var/lib/(docker|containers)($|/)|^/nix/store($|/)\",fstype!~\"tmpfs|squashfs|overlay|nsfs|fuse.lxcfs|tracefs|fuse.mergerfs\"}))";
                  legendFormat = "{{host}} {{mountpoint}}";
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
                unit = "celsius";
                decimals = 1;
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
                  expr = "node_hwmon_temp_celsius{job=\"remote-node\",chip=\"platform_coretemp_0\",sensor=\"temp1\"}";
                  legendFormat = "{{host}} CPU temp";
                  refId = "A";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"remote-node\",chip=\"nvme_nvme0\",sensor=\"temp1\"}";
                  legendFormat = "{{host}} nvme0 temp";
                  refId = "B";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"remote-node\",chip=\"nvme_nvme1\",sensor=\"temp1\"}";
                  legendFormat = "{{host}} nvme1 temp";
                  refId = "C";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"remote-node\",chip=~\".*(coretemp|k10temp|zenpower|cpu).*\",sensor=~\"(Package id 0|Tctl|Tdie|temp1)\",chip!=\"platform_coretemp_0\"}";
                  legendFormat = "{{host}} {{chip}} {{sensor}}";
                  refId = "D";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"remote-node\",chip=~\".*(jc42|spd|dimm|mem).*\"}";
                  legendFormat = "{{host}} {{chip}} {{sensor}}";
                  refId = "E";
                }
                {
                  expr = "node_hwmon_temp_celsius{job=\"remote-node\",chip=~\".*nvme.*\",chip!~\"nvme_nvme[01]\"}";
                  legendFormat = "{{host}} {{chip}} {{sensor}}";
                  refId = "F";
                }
                {
                  expr = "smartctl_device_temperature{job=\"remote-smartctl\"}";
                  legendFormat = "{{host}} {{device}}";
                  refId = "G";
                }
              ];
              title = "Hardware Temperatures";
              type = "timeseries";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              gridPos = {
                h = 10;
                w = 12;
                x = 0;
                y = 24;
              };
              id = 7;
              options = {
                cellHeight = "sm";
                footer = {
                  enablePagination = true;
                  fields = "";
                  reducer = [ "sum" ];
                  show = false;
                };
                showHeader = true;
              };
              targets = [
                {
                  expr = "max by (host, name) (node_systemd_unit_state{job=\"remote-node\",state=\"active\",name=~\".+\\\\.service\"})";
                  format = "table";
                  instant = true;
                  refId = "A";
                }
              ];
              title = "Active Service Units";
              transformations = [
                {
                  id = "organize";
                  options = {
                    excludeByName = {
                      "Time" = true;
                      "Value" = false;
                      "__name__" = true;
                      "instance" = true;
                      "job" = true;
                    };
                    indexByName = {
                      "host" = 0;
                      "name" = 1;
                      "Value" = 2;
                    };
                    renameByName = {
                      "Value" = "active";
                    };
                  };
                }
              ];
              type = "table";
            }
            {
              datasource = {
                type = "prometheus";
                uid = grafanaDatasourceUid;
              };
              gridPos = {
                h = 10;
                w = 12;
                x = 12;
                y = 24;
              };
              id = 8;
              options = {
                cellHeight = "sm";
                footer = {
                  enablePagination = true;
                  fields = "";
                  reducer = [ "sum" ];
                  show = false;
                };
                showHeader = true;
              };
              targets = [
                {
                  expr = "max by (host, name) (node_systemd_unit_state{job=\"remote-node\",state=\"failed\",name=~\".+\\\\.service\"})";
                  format = "table";
                  instant = true;
                  refId = "A";
                }
              ];
              title = "Failed Service Units";
              transformations = [
                {
                  id = "organize";
                  options = {
                    excludeByName = {
                      "Time" = true;
                      "Value" = false;
                      "__name__" = true;
                      "instance" = true;
                      "job" = true;
                    };
                    indexByName = {
                      "host" = 0;
                      "name" = 1;
                      "Value" = 2;
                    };
                    renameByName = {
                      "Value" = "failed";
                    };
                  };
                }
              ];
              type = "table";
            }
          ];
          refresh = "30s";
          schemaVersion = 39;
          tags = [
            "rpi"
            "naboo"
            "nevarro"
            "prometheus"
          ];
          templating.list = [ ];
          time = {
            from = "now-6h";
            to = "now";
          };
          timezone = "browser";
          title = "Naboo and Nevarro Overview";
          uid = "naboo-nevarro-overview";
          version = 1;
        }
      );
    in
    {
      options.my.monitoring = {
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
          description = "Optional Caddy environment variable used for monitoring basic authentication.";
        };
        enableSmartctlExporter = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        nodeTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        blockyTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        smartctlTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };
      config = lib.mkIf config.my.host.services.monitoring {
        sops.secrets.grafana_secret_key = {
          owner = "grafana";
          group = "grafana";
          mode = "0400";
          sopsFile = "${inputs.nix-secrets}/secrets.yaml";
        };
        my.localDns.records = [
          { hostname = cfg.grafanaHostName; }
          { hostname = cfg.prometheusHostName; }
        ];
        my.caddy.virtualHosts = {
          "${cfg.grafanaHostName}.{$DOMAIN}".routes = [
            "${
              lib.optionalString (
                cfg.basicAuthPasswordEnvVar != null
              ) "basic_auth /* { ${cfg.basicAuthUser} {\$${cfg.basicAuthPasswordEnvVar}} }\n"
            }reverse_proxy /* 127.0.0.1:3030"
          ];
          "${cfg.prometheusHostName}.{$DOMAIN}".routes = [
            "${
              lib.optionalString (
                cfg.basicAuthPasswordEnvVar != null
              ) "basic_auth /* { ${cfg.basicAuthUser} {\$${cfg.basicAuthPasswordEnvVar}} }\n"
            }reverse_proxy /* 127.0.0.1:9090"
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
              domain = "${cfg.grafanaHostName}.${domain}";
              enforce_domain = true;
              http_addr = "127.0.0.1";
              http_port = 3030;
              root_url = "https://${cfg.grafanaHostName}.${domain}/";
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
          webExternalUrl = "https://${cfg.prometheusHostName}.${domain}";
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
          ];
        };
      };
    };
}
