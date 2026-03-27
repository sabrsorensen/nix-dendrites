{
  inputs,
  lib,
  ...
}:
let
  clientId = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/netbird/clientId.txt");
in
{
  flake.modules.nixos.netbird =
    { config, ... }:
    let
      domain = config.systemConstants.domain;
      netbird_domain = "netbird.${domain}";
      netbird_mgmt_addr = "127.0.0.1";
      netbird_mgmt_port = 33073;
      netbird_relay_port = 33080;
    in
    {
      imports = [ inputs.self.modules.nixos.pocket-id ];
      sops.secrets = {
        "netbird/turn_password" = {
          group = "turnserver";
          mode = "0440";
          sopsFile = "${inputs.nix-secrets}/netbird/netbird.yaml";
        };
        "netbird/relay_secret" = {
          mode = "0400";
          sopsFile = "${inputs.nix-secrets}/netbird/netbird.yaml";
        };
        "netbird/data_store_encryption_key" = {
          mode = "0400";
          sopsFile = "${inputs.nix-secrets}/netbird/netbird.yaml";
        };
        "netbird-env" = {
          mode = "0400";
          format = "dotenv";
          sopsFile = "${inputs.nix-secrets}/netbird/netbird.env";
        };
        "netbird-relay-env" = {
          mode = "0400";
          format = "dotenv";
          sopsFile = "${inputs.nix-secrets}/netbird/relay.env";
        };
      };

      systemd.services.netbird-management.serviceConfig = {
        EnvironmentFile = config.sops.secrets."netbird-env".path;
      };

      services.netbird = {
        server = {
          enable = true;
          enableNginx = false;
          domain = netbird_domain;
          coturn = {
            enable = true;
            domain = netbird_mgmt_addr;
            passwordFile = config.sops.secrets."netbird/turn_password".path;
          };
          signal = {
            enable = true;
            enableNginx = false;
            domain = netbird_domain;
            port = 6443;
          };
          dashboard = {
            enable = true;
            enableNginx = false;
            domain = netbird_mgmt_addr;
            settings = {
              AUTH_AUTHORITY = "https://auth.${domain}/";
              AUTH_CLIENT_ID = clientId;
              AUTH_AUDIENCE = clientId;
            };
          };
          management = {
            enable = true;
            enableNginx = false;
            domain = netbird_mgmt_addr;
            singleAccountModeDomain = netbird_domain;
            port = netbird_mgmt_port;
            oidcConfigEndpoint = "https://auth.${domain}/.well-known/openid-configuration";
            settings = {
              Signal.URI = "${netbird_domain}:443";

              HttpConfig.AuthAudience = clientId;
              IdpManagerConfig.ClientConfig.ClientId = clientId;
              DeviceAuthorizationFlow.ProviderConfig = {
                Audience = clientId;
                ClientID = clientId;
              };
              PKCEAuthorizationFlow.ProviderConfig = {
                Audience = clientId;
                ClientID = clientId;
              };
              TURNConfig = {
                Secret._secret = config.sops.secrets."netbird/turn_password".path;
                CredentialsTTL = "12h";
                TimeBasedCredentials = false;
                Turns = [
                  {
                    Proto = "udp";
                    URI = "turn:${netbird_domain}:3478";
                    Username = "netbird";
                    Password._secret = config.sops.secrets."netbird/turn_password".path;
                  }
                ];
              };
              Relay = {
                Addresses = [ "rels://${netbird_domain}:443" ];
                CredentialsTTL = "24h";
                Secret._secret = config.sops.secrets."netbird/relay_secret".path;
              };
              DataStoreEncryptionKey._secret = config.sops.secrets."netbird/data_store_encryption_key".path;
            };
          };
        };
      };

      virtualisation.podman.enable = true;

      virtualisation.oci-containers.containers.netbird-relay = {
        image = "netbirdio/relay:latest";
        ports = [
          "33080:33080"
        ];
        environment = {
          NB_LOG_LEVEL = "debug";
          NB_LISTEN_ADDRESS = "0.0.0.0:33080";
          NB_EXPOSED_ADDRESS = "rels://${netbird_domain}:443";
        };
        environmentFiles = [
          config.sops.secrets."netbird-relay-env".path
        ];
      };

      services.caddy = {
        virtualHosts = {
          "netbird.{$DOMAIN}" = {
            logFormat = ''
              output stdout
              format console
              level DEBUG
            '';
            extraConfig = ''
              root * ${config.services.netbird.server.dashboard.finalDrv}

              reverse_proxy /api/* http://${netbird_mgmt_addr}:${toString netbird_mgmt_port}

              reverse_proxy /management.ManagementService/* h2c://${netbird_mgmt_addr}:${toString netbird_mgmt_port} {
                transport http {
                  read_timeout 0
                  write_timeout 0
                  dial_timeout 30s
                }
                flush_interval -1
              }

              reverse_proxy /ws-proxy/management/* http://${netbird_mgmt_addr}:${toString netbird_mgmt_port}

              reverse_proxy /signalexchange.SignalExchange/* h2c://${netbird_mgmt_addr}:${toString config.services.netbird.server.signal.port} {
                transport http {
                  read_timeout 0
                  write_timeout 0
                  dial_timeout 30s
                }
                flush_interval -1
              }

              reverse_proxy /ws-proxy/signal/* http://${netbird_mgmt_addr}:${toString config.services.netbird.server.signal.port}

              handle /relay {
                reverse_proxy http://${netbird_mgmt_addr}:${toString netbird_relay_port}
              }

              file_server
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [
        80
        443
        3478
        10000
        33080
      ];
      networking.firewall.allowedUDPPorts = [
        3478
        5349
        33080
      ];
      networking.firewall.allowedUDPPortRanges = [
        {
          from = 32768;
          to = 60999;
        }
      ];

      users.users.netbird = {
        isSystemUser = true;
        group = "netbird";
        createHome = true;
      };
      users.groups.netbird = { };

      systemd.tmpfiles.rules = [
        "d /var/lib/netbird 0750 netbird netbird -"
      ];
    };
}
