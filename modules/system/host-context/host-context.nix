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

        # Individual feature/service options are declared beside their owning
        # module (see e.g. modules/features/docker/docker.nix,
        # modules/services/plex/plex.nix). What remains here are aggregate
        # flags that cascade defaults onto several sub-features in
        # _host-context.nix, plus a couple of options with no single owning
        # module (see docs/architecture.md for the reasoning). Two flags
        # (wifi, personalMcpServers) are currently declared but consumed
        # nowhere in the repo -- left as-is pending a decision on whether
        # they're vestigial.
        features = {
          gui = lib.mkEnableOption "local graphical environment";
          wifi = lib.mkEnableOption "Wi-Fi";
          homeGuiPackages = lib.mkEnableOption "default graphical Home Manager packages";
          decky = lib.mkEnableOption "Decky Loader and declarative Decky plugins";
          impermanence = lib.mkEnableOption "persistent state on an ephemeral root filesystem";
          personalMcpServers = lib.mkEnableOption "Sam's personal MCP servers";
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

        # Every services.* option is now declared beside its owning module
        # (see e.g. modules/services/plex/plex.nix); this namespace has no
        # entries left to declare centrally.
        services = { };

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
