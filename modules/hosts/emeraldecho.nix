{
  config,
  inputs,
  lib,
  ...
}:
let
  steamdeckRoleModule = import ../roles/_steamdeck.nix { inherit inputs; };
  steamosLibraryModule =
    { lib, ... }:
    {
      home = {
        username = "deck";
        homeDirectory = "/home/deck";
        stateVersion = "24.11";
      };
      home.activation.setupSteamLibraryMount = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export PATH="/usr/bin:/bin:$PATH"

        FSTAB_ENTRY="/dev/disk/by-partlabel/jovian /srv/steam-library btrfs subvol=@steam,compress=zstd,noatime 0 0"
        MOUNT_POINT="/srv/steam-library"
        STEAMOS_READONLY_BIN=""

        if [ -x /usr/bin/steamos-readonly ]; then
          STEAMOS_READONLY_BIN=/usr/bin/steamos-readonly
        elif [ -x /bin/steamos-readonly ]; then
          STEAMOS_READONLY_BIN=/bin/steamos-readonly
        fi

        ensure_mount_point() {
          if [ ! -d "$MOUNT_POINT" ]; then
            echo "Creating mount point: $MOUNT_POINT"
            sudo mkdir -p "$MOUNT_POINT"
          fi
        }

        ensure_mount_owner() {
          mismatched_path="$(sudo find "$MOUNT_POINT" -xdev \( ! -user deck -o ! -group deck \) -print -quit 2>/dev/null || true)"
          if [ -n "$mismatched_path" ]; then
            echo "Updating Steam library ownership to deck:deck where needed"
            sudo find "$MOUNT_POINT" -xdev \( ! -user deck -o ! -group deck \) -exec chown deck:deck '{}' +
          fi
        }

        mount_steam_library() {
          ensure_mount_point
          if sudo mount "$MOUNT_POINT" 2>/dev/null; then
            echo "Successfully mounted Steam library"
            ensure_mount_owner
            return 0
          fi

          echo "Warning: Failed to mount Steam library (partition may not exist yet)"
          return 1
        }

        with_steamos_readwrite() {
          if [ -z "$STEAMOS_READONLY_BIN" ]; then
            "$@"
            return $?
          fi

          readonly_was_enabled=0
          if sudo "$STEAMOS_READONLY_BIN" status | grep -q "enabled"; then
            echo "Disabling SteamOS read-only mode..."
            sudo "$STEAMOS_READONLY_BIN" disable
            readonly_was_enabled=1
          fi

          "$@"
          status=$?
          if [ "$readonly_was_enabled" = "1" ]; then
            echo "Re-enabling SteamOS read-only mode..."
            sudo "$STEAMOS_READONLY_BIN" enable
          fi
          return "$status"
        }

        add_fstab_entry() {
          ensure_mount_point
          echo "Adding Steam library fstab entry..."
          echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
        }

        if [ -n "$STEAMOS_READONLY_BIN" ] || grep -q '^ID=steamos$' /etc/os-release 2>/dev/null; then
          if ! grep -q "/srv/steam-library" /etc/fstab 2>/dev/null; then
            with_steamos_readwrite add_fstab_entry
          fi
          if [ -e "/dev/disk/by-partlabel/jovian" ] && ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
            mount_steam_library
          elif mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
            ensure_mount_owner
          fi
        else
          echo "Not running on SteamOS, skipping Steam library mount setup"
        fi
      '';
    };
  hostModule = {
    networking.hostName = "EmeraldEcho";

    my.host = {
      name = "EmeraldEcho";
      formFactor = "handheld";
      home.enable = true;
      tags = [ "steamdeck-dualboot" ];
      roles.steamdeck = true;
      features = {
        gui = true;
        deskflow = true;
        firmware = true;
        noson = true;
      };
    };
    my.deployment = {
      enableRemoteUser = true;
      authorizedKeyFiles = [
        "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/emeraldecho_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/kamino/emeraldecho_nix.pub"
        "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/emeraldecho_nix.pub"
      ];
    };
  };
  bootstrapModule = lib.recursiveUpdate hostModule {
    my.host.tags = [
      "steamdeck-dualboot"
      "bootstrap"
    ];
    my.host.bootstrap.finalConfigName = "emeraldecho-dualboot";
    my.deployment.enableRemoteUser = false;
    users.users.sam = {
      isNormalUser = true;
      uid = lib.mkForce 1000;
      initialPassword = lib.mkForce "jovian";
      hashedPasswordFile = lib.mkForce null;
    };
    users.groups.sam.gid = lib.mkForce 1000;
    services.openssh.settings = {
      PasswordAuthentication = lib.mkForce true;
      KbdInteractiveAuthentication = lib.mkForce false;
    };
  };
  singleBootModule = lib.recursiveUpdate hostModule {
    my.host.tags = [ "steamdeck-singleboot" ];
    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "subvol=@root"
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "subvol=@home"
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "subvol=@nix"
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@steam" = {
                  mountpoint = "/srv/steam-library";
                  mountOptions = [
                    "subvol=@steam"
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
  singleBootBootstrapModule = lib.recursiveUpdate singleBootModule {
    my.host.tags = [
      "steamdeck-singleboot"
      "bootstrap"
    ];
    my.host.bootstrap.finalConfigName = "emeraldecho-singleboot";
    my.deployment.enableRemoteUser = false;
    users.users.sam = {
      isNormalUser = true;
      uid = lib.mkForce 1000;
      initialPassword = lib.mkForce "jovian";
      hashedPasswordFile = lib.mkForce null;
    };
    users.groups.sam.gid = lib.mkForce 1000;
    services.openssh.settings = {
      PasswordAuthentication = lib.mkForce true;
      KbdInteractiveAuthentication = lib.mkForce false;
    };
  };
  installerModule = lib.recursiveUpdate hostModule {
    networking.hostName = lib.mkForce "jovian-installer";
    my.host.tags = [
      "steamdeck-dualboot"
      "installer"
    ];
    my.host.home.enable = false;
    my.deployment.enableRemoteUser = false;
    users.users.jovian = {
      isNormalUser = true;
      description = "Steam Deck Installer User";
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
      ];
      initialPassword = "jovian";
    };
    services.displayManager.autoLogin.user = lib.mkForce "jovian";
    services.openssh.settings = {
      PasswordAuthentication = lib.mkForce true;
      PermitRootLogin = lib.mkForce "yes";
    };
    jovian.steam = {
      autoStart = lib.mkForce false;
      desktopSession = lib.mkForce null;
    };
    boot.loader.systemd-boot.enable = lib.mkForce false;
    documentation.enable = false;
  };
  installerIso =
    isDualBoot:
    { config, lib, ... }:
    {
      imports = [
        (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
      ];
      isoImage = {
        volumeID = if isDualBoot then "JOVIAN_DUALBOOT" else "JOVIAN_NIXOS";
        squashfsCompression = "gzip -Xcompression-level 1";
        makeEfiBootable = true;
        makeUsbBootable = true;
      };
      image.fileName = lib.mkForce "jovian-nixos-${lib.optionalString isDualBoot "dualboot-"}${config.system.nixos.label}.iso";
    };
in
{
  flake.homeConfigurations.emeraldecho-steamos = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
    modules = [ steamosLibraryModule ];
  };
  flake.nixosConfigurations.emeraldecho = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      hostModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      hostModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      bootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      bootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      singleBootModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot-bootstrap" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      singleBootBootstrapModule
    ];
  };
  flake.nixosConfigurations."emeraldecho-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      installerModule
      (installerIso true)
    ];
  };
  flake.nixosConfigurations."emeraldecho-dualboot-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      installerModule
      (installerIso true)
    ];
  };
  flake.nixosConfigurations."emeraldecho-singleboot-installer" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      steamdeckRoleModule
      (lib.recursiveUpdate singleBootModule installerModule)
      (installerIso false)
    ];
  };
}
