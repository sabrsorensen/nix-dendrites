{
  flake.modules.nixos.netbird-proxy =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.services.netbirdProxy.turnForward;
      targetHost =
        if cfg.targetHost == null then config.systemConstants.network.nevarro else cfg.targetHost;
    in
    {
      options.services.netbirdProxy.turnForward = {
        enable = lib.mkEnableOption "DNAT forwarding of NetBird TURN ports to the NetBird server host";

        externalInterface = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "enp2s0";
          description = "External interface on the proxy host receiving internet traffic for NetBird.";
        };

        targetHost = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "192.168.1.4";
          description = "LAN address of the NetBird server host. Defaults to systemConstants.network.nevarro.";
        };
      };

      config = {
        assertions = [
          {
            assertion = (!cfg.enable) || (cfg.externalInterface != null);
            message = "services.netbirdProxy.turnForward.externalInterface must be set when TURN forwarding is enabled.";
          }
        ];

        networking.nat = lib.mkIf cfg.enable {
          enable = true;
          externalInterface = cfg.externalInterface;
          forwardPorts = [
            {
              sourcePort = 3478;
              proto = "udp";
              destination = "${targetHost}:3478";
            }
            {
              sourcePort = 3478;
              proto = "tcp";
              destination = "${targetHost}:3478";
            }
            {
              sourcePort = 5349;
              proto = "udp";
              destination = "${targetHost}:5349";
            }
          ];
        };

        my.caddy.virtualHosts = {
          "auth.{$DOMAIN}" = {
            logFormat = ''
              output stdout
              format console
              level INFO
            '';
            routes = [
              ''
                reverse_proxy https://auth.{$DOMAIN} {
                  header_up Host {host}
                }
              ''
            ];
          };

          "netbird.{$DOMAIN}" = {
            logFormat = ''
              output file /var/log/caddy/netbird-proxy.log {
                roll_size 10mb
                roll_keep 5
                roll_keep_for 720h
              }
              format console
              level INFO
            '';
            routes = [
              ''
                @management path /management.ManagementService/*
                @signal path /signalexchange.SignalExchange/*
                @ws_mgmt path /ws-proxy/management/*
                @ws_signal path /ws-proxy/signal/*
                @relay path /relay*

                handle @management {
                  reverse_proxy https://netbird.{$DOMAIN} {
                    transport http {
                      versions 2 1.1
                      read_timeout 0
                      write_timeout 0
                      dial_timeout 30s
                    }
                    header_up X-Forwarded-For {remote_host}
                    header_up X-Forwarded-Proto {scheme}
                    header_up X-Real-IP {remote_host}
                    header_up Host netbird.{$DOMAIN}
                    flush_interval -1
                  }
                }

                handle @signal {
                  reverse_proxy https://netbird.{$DOMAIN} {
                    transport http {
                      versions 2 1.1
                      read_timeout 0
                      write_timeout 0
                      dial_timeout 30s
                    }
                    header_up X-Forwarded-For {remote_host}
                    header_up X-Forwarded-Proto {scheme}
                    header_up X-Real-IP {remote_host}
                    header_up Host netbird.{$DOMAIN}
                    flush_interval -1
                  }
                }

                handle @ws_mgmt {
                  reverse_proxy https://netbird.{$DOMAIN} {
                    transport http {
                      versions 2 1.1
                    }
                    header_up X-Forwarded-For {remote_host}
                    header_up X-Forwarded-Proto {scheme}
                    header_up X-Real-IP {remote_host}
                    header_up Host netbird.{$DOMAIN}
                    flush_interval -1
                  }
                }

                handle @ws_signal {
                  reverse_proxy https://netbird.{$DOMAIN} {
                    transport http {
                      versions 2 1.1
                    }
                    header_up X-Forwarded-For {remote_host}
                    header_up X-Forwarded-Proto {scheme}
                    header_up X-Real-IP {remote_host}
                    header_up Host netbird.{$DOMAIN}
                    flush_interval -1
                  }
                }

                handle @relay {
                  reverse_proxy https://netbird.{$DOMAIN} {
                    transport http {
                      versions 2 1.1
                      read_timeout 0
                      write_timeout 0
                      dial_timeout 30s
                    }
                    header_up X-Forwarded-For {remote_host}
                    header_up X-Forwarded-Proto {scheme}
                    header_up X-Real-IP {remote_host}
                    header_up Host netbird.{$DOMAIN}
                    flush_interval -1
                  }
                }

                handle {
                  reverse_proxy https://netbird.{$DOMAIN} {
                    transport http {
                      versions 2 1.1
                    }
                    header_up X-Forwarded-For {remote_host}
                    header_up X-Forwarded-Proto {scheme}
                    header_up X-Real-IP {remote_host}
                    header_up Host netbird.{$DOMAIN}
                  }
                }
              ''
            ];
          };
        };
      };
    };
}
