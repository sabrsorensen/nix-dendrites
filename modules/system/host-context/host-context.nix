{ ... }:
{
  # This module is registered like every other NixOS module.  Host outputs
  # broadcast the entire registry, so these options exist everywhere.
  flake.modules.nixos.host-context =
    args@{ config, lib, ... }:
    {
      options.my.host = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Canonical host name used by self-gating modules.";
        };

        address = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Primary LAN address used by local service publication.";
        };

        formFactor = lib.mkOption {
          type = lib.types.enum [
            "desktop"
            "laptop"
            "handheld"
            "server"
            "vm"
          ];
          description = "Physical or operational shape of the host.";
        };

        platform = lib.mkOption {
          type = lib.types.enum [
            "generic"
            "rpi"
            "steamdeck"
            "wsl"
          ];
          default = "generic";
          description = "Operating-system and hardware integration selected by this host.";
        };

        tags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Sparse grouping and exception labels.";
        };

        home = {
          enable = lib.mkEnableOption "the managed Home Manager profile for this host's primary user";
          username = lib.mkOption {
            type = lib.types.str;
            default = if config.my.host.platform == "wsl" then "ssorensen" else "sam";
            description = "Primary Home Manager username for this host.";
          };
          homeDirectory = lib.mkOption {
            type = lib.types.str;
            default = "/home/${config.my.host.home.username}";
            description = "Primary Home Manager home directory for this host.";
          };
        };

        bootstrap.finalConfigName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "NixOS configuration to select after bootstrap enrollment.";
        };

        bootstrap.instructionsPath = lib.mkOption {
          type = lib.types.str;
          default = "/etc/bootstrap-enroll.txt";
          description = "Path where bootstrap enrollment instructions are published.";
        };

        roles = {
          workstation = lib.mkEnableOption "workstation role";
          desktop = lib.mkEnableOption "desktop role";
          server = lib.mkEnableOption "server role";
          builder = lib.mkEnableOption "builder role";
        };

        features = {
          armory = lib.mkEnableOption "Bitcoin Armory wallet tooling";
          gui = lib.mkEnableOption "local graphical environment";
          appimage = lib.mkEnableOption "AppImage integration";
          atuin = lib.mkEnableOption "Atuin Home Manager client";
          audio = lib.mkEnableOption "local audio stack";
          bluetooth = lib.mkEnableOption "Bluetooth";
          desktop = lib.mkEnableOption "generic desktop session";
          wifi = lib.mkEnableOption "Wi-Fi";
          firmware = lib.mkEnableOption "redistributable firmware";
          firefox = lib.mkEnableOption "Firefox browser profile";
          nix-ld = lib.mkEnableOption "nix-ld compatibility";
          nvidia = lib.mkEnableOption "NVIDIA support";
          flatpak = lib.mkEnableOption "Flatpak";
          docker = lib.mkEnableOption "Docker container runtime";
          podman = lib.mkEnableOption "Podman container runtime";
          determinateNix = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to use Determinate Nix instead of the upstream Nix daemon.";
          };
          decky = lib.mkEnableOption "Decky Loader and declarative Decky plugins";
          deckyCatalog = lib.mkEnableOption "declarative Decky plugin catalogue";
          deckyLoader = lib.mkEnableOption "Decky Loader";
          deckyPlugins = lib.mkEnableOption "declarative Decky plugin staging";
          homeGuiPackages = lib.mkEnableOption "default graphical Home Manager packages";
          konsole = lib.mkEnableOption "Konsole terminal profile";
          localGuiTools = lib.mkEnableOption "local graphical maintenance tools";
          plymouth = lib.mkEnableOption "Plymouth boot splash";
          steam = lib.mkEnableOption "Steam";
          wayland = lib.mkEnableOption "Wayland session environment";
          wine = lib.mkEnableOption "Wine";
          deskflow = lib.mkEnableOption "Deskflow";
          minecraft = lib.mkEnableOption "Minecraft tooling";
          threedprinter = lib.mkEnableOption "3D-printer tooling";
          zsa = lib.mkEnableOption "ZSA tooling";
          beets = lib.mkEnableOption "Beets music-library management";
          bitwarden = lib.mkEnableOption "Bitwarden";
          demlo = lib.mkEnableOption "Demlo audio-file processing";
          noson = lib.mkEnableOption "Noson";
          impermanence = lib.mkEnableOption "persistent state on an ephemeral root filesystem";
          mcpCommon = lib.mkEnableOption "common MCP client profile";
          persistenceBluetooth = lib.mkEnableOption "Bluetooth persistent state";
          persistenceFirefox = lib.mkEnableOption "Firefox persistent state";
          persistenceHome = lib.mkEnableOption "Home Manager persistent state";
          persistenceSystem = lib.mkEnableOption "system persistent state";
          lazyvim = lib.mkEnableOption "LazyVim editor configuration";
          office = lib.mkEnableOption "office tools";
          gdrive = lib.mkEnableOption "Sam's rclone Google Drive mount";
          personalMcp = lib.mkEnableOption "Sam's personal MCP client profile";
          personalMcpServers = lib.mkEnableOption "Sam's personal MCP servers";
          vscode = lib.mkEnableOption "the declarative VSCodium editor profile";
        };

        vscodeTheme = lib.mkOption {
          type = lib.types.enum [
            "partyowl84"
            "synthwave-blues"
            "synthwave-84"
          ];
          default = "partyowl84";
          description = "Baked VSCodium theme selected when the vscode feature is enabled.";
        };

        services = {
          ankerctl = lib.mkEnableOption "AnkerCtl printer-control service";
          airsonic = lib.mkEnableOption "Airsonic music service";
          apprise = lib.mkEnableOption "Apprise notification service";
          arrSync = lib.mkEnableOption "Arr Sync webhook service";
          attic = lib.mkEnableOption "Attic cache service";
          atuinServer = lib.mkEnableOption "Atuin history-sync server";
          bazarr = lib.mkEnableOption "Bazarr media service";
          blocky = lib.mkEnableOption "Blocky DNS service";
          caddy = lib.mkEnableOption "Caddy reverse proxy";
          dhcpCoredns = lib.mkEnableOption "Kea DHCP with CoreDNS updates";
          deluge = lib.mkEnableOption "Deluge download service with Gluetun VPN";
          flaresolverr = lib.mkEnableOption "FlareSolverr media dependency";
          frigate = lib.mkEnableOption "Frigate NVR service";
          immich = lib.mkEnableOption "Immich service";
          jellyfin = lib.mkEnableOption "Jellyfin media service";
          mealie = lib.mkEnableOption "Mealie service";
          minecraft = lib.mkEnableOption "Minecraft server";
          monitoring = lib.mkEnableOption "monitoring services";
          monitoringExporters = lib.mkEnableOption "Prometheus node and SMART exporter services";
          netbirdClient = lib.mkEnableOption "NetBird overlay-network client";
          netbirdServer = lib.mkEnableOption "NetBird server topology";
          gonic = lib.mkEnableOption "Gonic music service";
          gotify = lib.mkEnableOption "Gotify notification service";
          hawkbit = lib.mkEnableOption "hawkBit device-management service";
          plex = lib.mkEnableOption "Plex media-service bundle";
          profilarr = lib.mkEnableOption "Profilarr media service";
          prowlarr = lib.mkEnableOption "Prowlarr media service";
          radarr = lib.mkEnableOption "Radarr media service";
          sonarr = lib.mkEnableOption "Sonarr media service";
          ntfy = lib.mkEnableOption "ntfy notification service";
          nextcloud = lib.mkEnableOption "Nextcloud with Collabora Online";
          ombi = lib.mkEnableOption "Ombi media-request service";
          organizr = lib.mkEnableOption "Organizr media dashboard";
          samba = lib.mkEnableOption "Samba shares";
          scrutiny = lib.mkEnableOption "Scrutiny disk monitoring";
          ssh = lib.mkEnableOption "OpenSSH server defaults";
          syncthing = lib.mkEnableOption "system Syncthing";
          watchtower = lib.mkEnableOption "Watchtower container-update service";
        };

        is = {
          workstation = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
          };
          desktopSession = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
          };
          server = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
          };
          rpi = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
          };
          steamdeck = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
          };
          headless = lib.mkOption {
            type = lib.types.bool;
            readOnly = true;
          };
        };
      };

      options.my.unfreePackageNames = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Unfree package names requested by self-gating modules.";
      };

      options.my.deployment = {
        enableRemoteUser = lib.mkEnableOption "the restricted nix-remote deployment account";
        canDeployRemotely = lib.mkEnableOption "remote deployment commands from this host";
        sleepy = lib.mkEnableOption "a blocking systemd sleep-inhibition lease for long-running deployment commands";
        authorizedKeyFiles = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "Public keys permitted to use the nix-remote deployment account.";
        };
        localFlakePath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Checkout used by nh for local and remote deployment.";
        };
      };

      options.my.media = {
        configRoot = lib.mkOption {
          type = lib.types.str;
          default = "/opt";
          description = "Base path for persistent media service configuration.";
        };
        dataRoot = lib.mkOption {
          type = lib.types.str;
          default = "/srv/media";
          description = "Base path for shared media-library data.";
        };
        dnsServers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Resolvers explicitly supplied to media containers.";
        };
        podmanNetwork = lib.mkOption {
          type = lib.types.str;
          default = "media";
          description = "Podman network used by media containers.";
        };
        containerIdentities = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                uid = lib.mkOption { type = lib.types.either lib.types.int lib.types.str; };
                gid = lib.mkOption { type = lib.types.either lib.types.int lib.types.str; };
              };
            }
          );
          default = { };
          description = "Pinned UID/GID assignments for media container workloads.";
        };
      };

      options.my.localDns = {
        records = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                hostname = lib.mkOption { type = lib.types.str; };
                ip = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
              };
            }
          );
          default = [ ];
          description = "Short hostnames published by this host or its services.";
        };

        publishedRecords = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                hostname = lib.mkOption { type = lib.types.str; };
                ip = lib.mkOption { type = lib.types.str; };
              };
            }
          );
          readOnly = true;
          description = "Local DNS records materialized with an address.";
        };
      };

      config = import ./_host-context.nix args;
    };
}
