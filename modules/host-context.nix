{ ... }:
{
  # This module is registered like every other NixOS module.  Host outputs
  # broadcast the entire registry, so these options exist everywhere.
  flake.modules.nixos.host-context =
    { config, lib, ... }:
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

        tags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Sparse grouping and exception labels.";
        };

        bootstrap.finalConfigName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "NixOS configuration to select after bootstrap enrollment.";
        };

        roles = {
          workstation = lib.mkEnableOption "workstation role";
          desktop = lib.mkEnableOption "desktop role";
          server = lib.mkEnableOption "server role";
          builder = lib.mkEnableOption "builder role";
          rpi = lib.mkEnableOption "Raspberry Pi role";
          steamdeck = lib.mkEnableOption "Steam Deck role";
          wsl = lib.mkEnableOption "WSL role";
        };

        features = {
          armory = lib.mkEnableOption "Bitcoin Armory wallet tooling";
          gui = lib.mkEnableOption "local graphical environment";
          bluetooth = lib.mkEnableOption "Bluetooth";
          wifi = lib.mkEnableOption "Wi-Fi";
          firmware = lib.mkEnableOption "redistributable firmware";
          nix-ld = lib.mkEnableOption "nix-ld compatibility";
          nvidia = lib.mkEnableOption "NVIDIA support";
          flatpak = lib.mkEnableOption "Flatpak";
          docker = lib.mkEnableOption "Docker container runtime";
          podman = lib.mkEnableOption "Podman container runtime";
          steam = lib.mkEnableOption "Steam";
          wine = lib.mkEnableOption "Wine";
          deskflow = lib.mkEnableOption "Deskflow";
          minecraft = lib.mkEnableOption "Minecraft tooling";
          threedprinter = lib.mkEnableOption "3D-printer tooling";
          zsa = lib.mkEnableOption "ZSA tooling";
          bitwarden = lib.mkEnableOption "Bitwarden";
          noson = lib.mkEnableOption "Noson";
          musicTagging = lib.mkEnableOption "music tagging tools";
          impermanence = lib.mkEnableOption "persistent state on an ephemeral root filesystem";
          lazyvim = lib.mkEnableOption "LazyVim editor configuration";
          office = lib.mkEnableOption "office tools";
          gdrive = lib.mkEnableOption "Sam's rclone Google Drive mount";
          personalMcp = lib.mkEnableOption "Sam's personal MCP client profile";
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
          atuin = lib.mkEnableOption "Atuin history-sync service";
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
          netbirdClient = lib.mkEnableOption "NetBird overlay-network client";
          netbirdServer = lib.mkEnableOption "NetBird server topology";
          gonic = lib.mkEnableOption "Gonic music service";
          gotify = lib.mkEnableOption "Gotify notification service";
          plex = lib.mkEnableOption "Plex media-service bundle";
          profilarr = lib.mkEnableOption "Profilarr media service";
          prowlarr = lib.mkEnableOption "Prowlarr media service";
          radarr = lib.mkEnableOption "Radarr media service";
          sonarr = lib.mkEnableOption "Sonarr media service";
          ntfy = lib.mkEnableOption "ntfy notification service";
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

      config = {
        my.host.is = {
          workstation = config.my.host.roles.workstation || config.my.host.features.gui;
          desktopSession =
            config.my.host.features.gui && !config.my.host.roles.steamdeck && !config.my.host.roles.wsl;
          server = config.my.host.roles.server;
          rpi = config.my.host.roles.rpi;
          steamdeck = config.my.host.roles.steamdeck;
          headless = !config.my.host.features.gui;
        };

        nixpkgs.config.allowUnfreePredicate =
          pkg: builtins.elem (lib.getName pkg) config.my.unfreePackageNames;

        my.localDns.publishedRecords = lib.filter (record: record.ip != null) (
          map (
            record: record // { ip = if record.ip != null then record.ip else config.my.host.address; }
          ) config.my.localDns.records
        );
      };
    };
}
