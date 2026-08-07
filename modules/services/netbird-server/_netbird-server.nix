{
  config,
  lib,
  pkgs,
  inputs,
  clientId,
  domain,
  managementAddress,
  managementPort,
  relayPort,
  netbirdDomain,
  ...
}:
{
  assertions = [
    {
      assertion = config.my.host.features.podman;
      message = "NetBird server requires features.podman for its relay container.";
    }
  ];
  my.localDns.records = [
    { hostname = "auth"; }
    { hostname = "netbird"; }
  ];
  sops.secrets = {
    pocket-id = {
      mode = "0400";
      format = "dotenv";
      sopsFile = "${inputs.nix-secrets}/pocket-id.env";
      key = "";
    };
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
    netbird-env = {
      mode = "0400";
      format = "dotenv";
      sopsFile = "${inputs.nix-secrets}/netbird/netbird.env";
      key = "";
    };
    netbird-relay-env = {
      mode = "0400";
      format = "dotenv";
      sopsFile = "${inputs.nix-secrets}/netbird/relay.env";
      key = "";
    };
  };
  systemd.services.netbird-management.serviceConfig.EnvironmentFile =
    config.sops.secrets.netbird-env.path;
  services.pocket-id = {
    enable = true;
    package = pkgs.pocket-id;
    settings = {
      APP_URL = "https://auth.${domain}";
      ANALYTICS_DISABLED = true;
      TRUST_PROXY = true;
    };
    environmentFile = config.sops.secrets.pocket-id.path;
  };
  my.caddy.virtualHosts = {
    "auth.{$DOMAIN}" = {
      logFormat = "output stdout\nformat console\nlevel INFO";
      routes = [ "import cors https://auth.{$DOMAIN}\nreverse_proxy http://127.0.0.1:1411" ];
    };
    "netbird.{$DOMAIN}" = {
      logFormat = "output stdout\nformat console\nlevel INFO";
      routes = [
        ''
          root * ${config.services.netbird.server.dashboard.finalDrv}
          reverse_proxy /api/* http://${managementAddress}:${toString managementPort}
          reverse_proxy /management.ManagementService/* h2c://${managementAddress}:${toString managementPort} { transport http { read_timeout 0 write_timeout 0 dial_timeout 30s } flush_interval -1 }
          reverse_proxy /ws-proxy/management/* http://${managementAddress}:${toString managementPort}
          reverse_proxy /signalexchange.SignalExchange/* h2c://${managementAddress}:${toString config.services.netbird.server.signal.port} { transport http { read_timeout 0 write_timeout 0 dial_timeout 30s } flush_interval -1 }
          reverse_proxy /ws-proxy/signal/* http://${managementAddress}:${toString config.services.netbird.server.signal.port}
          handle /relay { reverse_proxy http://${managementAddress}:${toString relayPort} }
          file_server
        ''
      ];
    };
  };
  services.netbird = {
    useRoutingFeatures = lib.mkForce "server";
    server = {
      enable = true;
      enableNginx = false;
      domain = netbirdDomain;
      coturn = {
        enable = true;
        domain = managementAddress;
        passwordFile = config.sops.secrets."netbird/turn_password".path;
      };
      signal = {
        enable = true;
        enableNginx = false;
        domain = netbirdDomain;
        port = 6443;
      };
      dashboard = {
        enable = true;
        enableNginx = false;
        domain = managementAddress;
        settings = {
          AUTH_AUTHORITY = "https://auth.${domain}/";
          AUTH_CLIENT_ID = clientId;
          AUTH_AUDIENCE = clientId;
        };
      };
      management = {
        enable = true;
        enableNginx = false;
        domain = managementAddress;
        singleAccountModeDomain = netbirdDomain;
        port = managementPort;
        oidcConfigEndpoint = "https://auth.${domain}/.well-known/openid-configuration";
        settings = {
          Signal.URI = "${netbirdDomain}:443";
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
                URI = "turn:${netbirdDomain}:3478";
                Username = "netbird";
                Password._secret = config.sops.secrets."netbird/turn_password".path;
              }
            ];
          };
          Relay = {
            Addresses = [ "rels://${netbirdDomain}:443" ];
            CredentialsTTL = "24h";
            Secret._secret = config.sops.secrets."netbird/relay_secret".path;
          };
          DataStoreEncryptionKey._secret = config.sops.secrets."netbird/data_store_encryption_key".path;
        };
      };
    };
  };
  virtualisation.oci-containers.containers.netbird-relay = {
    image = "netbirdio/relay:0.71.4";
    ports = [ "${toString relayPort}:${toString relayPort}" ];
    environment = {
      NB_LOG_LEVEL = "debug";
      NB_LISTEN_ADDRESS = "0.0.0.0:${toString relayPort}";
      NB_EXPOSED_ADDRESS = "rels://${netbirdDomain}:443";
    };
    environmentFiles = [ config.sops.secrets.netbird-relay-env.path ];
  };
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
      3478
      10000
      relayPort
    ];
    allowedUDPPorts = [
      3478
      5349
      relayPort
    ];
    allowedUDPPortRanges = [
      {
        from = 32768;
        to = 60999;
      }
    ];
  };
  users.users.netbird = {
    isSystemUser = true;
    group = "netbird";
    createHome = true;
  };
  users.groups.netbird = { };
  systemd.tmpfiles.rules = [ "d /var/lib/netbird 0750 netbird netbird -" ];
}
