{ lib }:
{
  mkSharedHostOptions =
    {
      nameDefault,
      nameDescription,
      domainDefault ? null,
      domainDescription,
      includeAddress ? false,
      includeDeployEnableRemoteUser ? false,
      includeDeployLocalFlakePath ? false,
      includeNixBuildMachines ? false,
    }:
    {
      name = lib.mkOption {
        type = lib.types.str;
        default = nameDefault;
        description = nameDescription;
      };

      domain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = domainDefault;
        description = domainDescription;
      };
    }
    // lib.optionalAttrs includeAddress {
      address = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Primary LAN address associated with this host.";
      };
    }
    // {
      roles = {
        workstation = lib.mkEnableOption "workstation host role";
        desktop = lib.mkEnableOption "desktop host role";
        server = lib.mkEnableOption "server host role";
        rpi = lib.mkEnableOption "Raspberry Pi host role";
        serviceHost = lib.mkEnableOption "service-host role";
        steamdeck = lib.mkEnableOption "Steam Deck host role";
        wsl = lib.mkEnableOption "WSL host role";
      };

      deploy =
        {
          canDeployRemotely = lib.mkEnableOption "remote deployment commands for this host";
          sleepy = lib.mkEnableOption "sleep inhibition for long-running local operations";
        }
        // lib.optionalAttrs includeDeployEnableRemoteUser {
          enableRemoteUser = lib.mkEnableOption "nix-remote deployment user on this host";
        }
        // lib.optionalAttrs includeDeployLocalFlakePath {
          localFlakePath = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Local flake path used by deployment helpers on this host.";
          };
        };

      syncthing = {
        mode = lib.mkOption {
          type = lib.types.enum [
            "disabled"
            "home"
            "system"
          ];
          default = "disabled";
          description = "Preferred Syncthing integration mode for this host.";
        };

        hasTray = lib.mkEnableOption "Syncthing tray support on this host";
      };

      ssh.enableNixBlocks = lib.mkEnableOption "nix-remote SSH blocks on this host";
    }
    // lib.optionalAttrs includeNixBuildMachines {
      nix.buildMachines = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "Distributed build machine definitions for this host.";
      };
    };
}
