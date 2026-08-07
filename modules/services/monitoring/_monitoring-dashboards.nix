{ pkgs }:
let
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
  inherit
    grafanaBlockyDashboard
    grafanaDashboard
    grafanaRpiServicesDashboard
    ;
}
