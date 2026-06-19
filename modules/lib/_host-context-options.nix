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

      formFactor = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "desktop"
            "laptop"
            "handheld"
            "server"
            "vm"
          ]
        );
        default = null;
        description = "Physical or operational form factor used for shared module behavior.";
      };

      lifecycle.mode = lib.mkOption {
        type = lib.types.enum [
          "system"
          "bootstrap"
          "installer"
        ];
        default = "system";
        description = "Operational lifecycle mode for this host configuration.";
      };

      tags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Freeform host tags for cross-cutting grouping and exceptions.";
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
      primaryInteractiveUser = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Primary human user for this host's interactive login and host-edge user defaults.";
      };

      roles = {
        workstation = lib.mkEnableOption "workstation host role";
        desktop = lib.mkEnableOption "desktop host role";
        server = lib.mkEnableOption "server host role";
        builder = lib.mkEnableOption "build machine host role";
        rpi = lib.mkEnableOption "Raspberry Pi host role";
        serviceHost = lib.mkEnableOption "service-host role";
        steamdeck = lib.mkEnableOption "Steam Deck host role";
        wsl = lib.mkEnableOption "WSL host role";
      };

      deploy = {
        canDeployRemotely = lib.mkEnableOption "remote deployment commands for this host";
        sleepy = lib.mkEnableOption "sleep inhibition for long-running local operations";
      }
      // lib.optionalAttrs includeDeployEnableRemoteUser {
        enableRemoteUser = lib.mkEnableOption "nix-remote deployment user on this host";
      }
      // lib.optionalAttrs includeDeployLocalFlakePath {
        localUser = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Local user that owns the flake checkout used for self-deploy workflows.";
        };

        repoName = lib.mkOption {
          type = lib.types.str;
          default = "nix-dendrites";
          description = "Repository directory name used for local self-deploy workflows.";
        };

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

      features = {
        gui = lib.mkEnableOption "graphical local session support on this host";
        bluetooth = lib.mkEnableOption "Bluetooth support on this host";
        wifi = lib.mkEnableOption "Wi-Fi support on this host";
        nvidia = lib.mkEnableOption "NVIDIA graphics support on this host";
        flatpak = lib.mkEnableOption "Flatpak support on this host";
        steam = lib.mkEnableOption "Steam or Steam-adjacent gaming support on this host";
        wine = lib.mkEnableOption "Wine and related Windows compatibility tools on this host";
      };

      is = {
        workstation = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived workstation flag for modules.";
        };

        server = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived server flag for modules.";
        };

        builder = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived builder flag for modules.";
        };

        desktop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived physical desktop flag for modules.";
        };

        laptop = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived laptop flag for modules.";
        };

        handheld = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived handheld flag for modules.";
        };

        steamdeck = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived Steam Deck flag for modules.";
        };

        rpi = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived Raspberry Pi flag for modules.";
        };

        wsl = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Derived WSL flag for modules.";
        };

        headless = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Derived headless flag for modules.";
        };
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
