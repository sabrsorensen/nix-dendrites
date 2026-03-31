{
  inputs,
  lib,
  ...
}:
let
  root = ../../../..;
  steamUser = "sam";
  installerUser = "jovian";

  mkEmeraldHomeModule =
    { lib, pkgs, ... }:
    let
      xrDriverRuntimeLibs = pkgs.lib.makeLibraryPath (
        with pkgs;
        [
          libevdev
          json_c
          curl
          openssl
          libusb1
          systemd
          wayland
        ]
      );
      steamConfigPython = pkgs.python3.withPackages (ps: [ ps.vdf ]);
      steamConfigSeedScript = pkgs.writeText "steam-config-seed.py" ''
        import collections
        import pathlib
        import shutil
        import sys

        import vdf

        config_path = pathlib.Path.home() / ".local/share/Steam/config/config.vdf"
        config_path.parent.mkdir(parents=True, exist_ok=True)

        STEAM_VALUES = {
            "WifiPowerManagementEnabled": "1",
            "AllowBatteryLowPowerDownloads": "1",
        }
        SHADER_CACHE_VALUES = {
            "EnableShaderBackgroundProcessing": "1",
        }
        UI_DISPLAY_CURRENT_VALUES = {
            "ScaleFactor": "1.2",
        }
        UI_DISPLAY_INTERNAL_VALUES = {
            "ScaleFactor": "1.2",
        }
        STEAMOS_VALUES = {
            "ChargeLimitEnabled": "1",
            "ChargeLimit": "90",
        }

        def nested_setdefault(mapping, keys):
            current = mapping
            for key in keys:
                current = current.setdefault(key, collections.OrderedDict())
            return current

        install_config = collections.OrderedDict()
        if config_path.exists():
            backup_path = config_path.with_suffix(config_path.suffix + ".pre-nix-backup")
            shutil.copy2(config_path, backup_path)
            try:
                with config_path.open("r", encoding="utf-8") as fp:
                    install_config = vdf.load(fp, mapper=collections.OrderedDict)
            except Exception as exc:
                print(f"Failed to parse {config_path}: {exc}", file=sys.stderr)
                raise SystemExit(0)

        root = install_config.setdefault("InstallConfigStore", collections.OrderedDict())
        steam = nested_setdefault(root, ["Software", "Valve", "Steam"])
        system = steam.setdefault("System", collections.OrderedDict())
        system.update(STEAM_VALUES)
        shader_cache = steam.setdefault("ShaderCacheManager", collections.OrderedDict())
        shader_cache.update(SHADER_CACHE_VALUES)

        ui = root.setdefault("UI", collections.OrderedDict())
        display = ui.setdefault("display", collections.OrderedDict())
        current_display = display.setdefault("Current", collections.OrderedDict())
        current_display.update(UI_DISPLAY_CURRENT_VALUES)
        internal_display = display.setdefault('Internal: gamescope 7"', collections.OrderedDict())
        internal_display.update(UI_DISPLAY_INTERNAL_VALUES)

        steamos = root.setdefault("SteamOS", collections.OrderedDict())
        steamos.update(STEAMOS_VALUES)

        with config_path.open("w", encoding="utf-8") as fp:
            vdf.dump(install_config, fp, pretty=True, escaped=True)
      '';
    in
    {
      imports = [
        ./_steamdeck/steamdeck-shortcut.nix
      ]
      ++ (with inputs.self.modules.homeManager; [
        firefox
        vscode
      ]);

      home.file = {
        ".config/reshade/Shaders/.keep".text = "";
        ".config/reshade/Textures/.keep".text = "";
        ".local/share/gamescope/reshade/Shaders/.keep".text = "";
        ".local/share/gamescope/reshade/Textures/.keep".text = "";
        ".local/share/breezy_vulkan/.keep".text = "";
      };

      systemd.user.services.xr-driver = {
        Unit = {
          Description = "XR user-space driver";
          After = [ "default.target" ];
          ConditionPathExists = "%h/.local/bin/xrDriver";
        };
        Service = {
          Type = "simple";
          Environment = [
            "LD_LIBRARY_PATH=%h/.local/share/xr_driver/lib:${xrDriverRuntimeLibs}"
          ];
          ExecStart = "%h/.local/bin/xrDriver";
          Restart = "always";
        };
        Install.WantedBy = [ "default.target" ];
      };

      home.activation.xrDriverCleanup = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        rm -f "$HOME/.config/systemd/user/default.target.wants/xr-driver.service"
      '';

      home.activation.seedSteamConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${steamConfigPython}/bin/python3 ${steamConfigSeedScript}
      '';
    };

  mkEmeraldSystemModule =
    bootMode:
    { config, pkgs, ... }:
    {
      imports = with inputs.self.modules.nixos; [
        system-cli
        disko
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.jovian-nixos.nixosModules.default
        ./_decky/decky-plugins.nix
        ./_decky/steamdeck-decky.nix
        ./_decky/steamdeck-plugins.nix
        (import ./_steamdeck/steamdeck-hw-config.nix bootMode)
        ./_steamdeck/steamdeck-steam.nix
        ./_steamdeck/steamdeck-system.nix
      ];

      users.users.${steamUser} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "video"
        ];
        uid = lib.mkForce 1000;
        hashedPasswordFile = config.sops.secrets.hashed_password.path;
        openssh.authorizedKeys.keyFiles = [
          "${inputs.nix-secrets}/ssh-keys/atlas_emeraldecho.pub"
          "${inputs.nix-secrets}/ssh-keys/kamino_emeraldecho.pub"
          "${inputs.nix-secrets}/ssh-keys/zaphod_emeraldecho.pub"
          "${inputs.nix-secrets}/ssh-keys/wsl_emeraldecho.pub"
        ];
      };

      users.groups.${steamUser}.gid = lib.mkForce 1000;

      users.users.nix-remote = {
        openssh.authorizedKeys.keyFiles = [
          "${inputs.nix-secrets}/ssh-keys/atlas_emeraldecho_nix.pub"
          "${inputs.nix-secrets}/ssh-keys/zaphod_emeraldecho_nix.pub"
        ];
      };

      home-manager.users.${steamUser}.imports = [
        inputs.self.modules.homeManager.sam
        inputs.self.modules.homeManager.EmeraldEcho
      ];

      networking.firewall.allowedTCPPorts = [
        1400
        3400
        24800
      ];
      networking.firewall.allowedUDPPorts = [ 24800 ];

      environment.systemPackages = with pkgs; [
        bitwarden-desktop
        deskflow
        noson
        rclone
        signal-desktop
        vlc
      ];

      programs.kdeconnect.enable = true;
    };

  mkEmeraldBootstrapModule =
    bootMode:
    { lib, ... }:
    let
      isDualBoot = bootMode == "dual";
    in
    {
      imports = with inputs.self.modules.nixos; [
        system-minimal
        home-manager
        ssh
        firmware
        cli-tools
        locale
        disko
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.jovian-nixos.nixosModules.default
        (import ./_steamdeck/steamdeck-hw-config.nix bootMode)
        ./_steamdeck/steamdeck-steam.nix
        ./_steamdeck/steamdeck-system.nix
      ];

      users.users.${steamUser} = {
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "video"
        ];
        hashedPasswordFile = lib.mkForce null;
        initialPassword = "jovian";
      }
      // lib.optionalAttrs isDualBoot {
        uid = lib.mkForce 1000;
      };

      users.groups.${steamUser} = lib.optionalAttrs isDualBoot {
        gid = lib.mkForce 1000;
      };

      home-manager.users.${steamUser} = {
        home.username = steamUser;
        home.homeDirectory = "/home/${steamUser}";
        home.stateVersion = "26.05";
        imports = [ ./_steamdeck/steamdeck-shortcut.nix ];
      };
    };

  mkEmeraldInstallerModule =
    bootMode:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      isDualBoot = bootMode == "dual";
      diskConfigFile =
        if isDualBoot then "steamdeck-dualboot-disk-config.nix" else "steamdeck-singleboot-disk-config.nix";
      diskConfigPath =
        if isDualBoot then
          ./_steamdeck/disk-configs/steamdeck-dualboot-disk-config.nix
        else
          ./_steamdeck/disk-configs/steamdeck-singleboot-disk-config.nix;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.jovian-nixos.nixosModules.default
        (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
        (import ./_steamdeck/steamdeck-hw-config.nix bootMode)
        ./_steamdeck/steamdeck-steam.nix
        ./_steamdeck/steamdeck-system.nix
      ];

      nixpkgs.config.allowUnfree = true;

      networking.hostName = lib.mkForce "jovian-installer";

      users.users.nixos.enable = lib.mkForce false;
      services.displayManager.autoLogin.user = lib.mkForce installerUser;
      jovian = {
        decky-loader.enable = lib.mkForce false;
        steam = {
          autoStart = lib.mkForce false;
          user = lib.mkForce installerUser;
          desktopSession = lib.mkForce null;
        };
      };

      image = {
        baseName = lib.mkForce (
          lib.concatStringsSep "-" (
            [
              "jovian"
              "nixos"
            ]
            ++ lib.optionals isDualBoot [ "dualboot" ]
            ++ [
              (lib.optionalString (config.isoImage.edition != "") config.isoImage.edition)
              config.system.nixos.label
              system
            ]
          )
        );
        fileName = lib.mkForce (config.image.baseName + ".iso");
      };

      isoImage = {
        volumeID = if isDualBoot then "JOVIAN_DUALBOOT" else "JOVIAN_NIXOS";
        squashfsCompression = "gzip -Xcompression-level 1";
        makeEfiBootable = true;
        makeUsbBootable = true;
        contents = [
          {
            source = lib.sources.cleanSourceWith {
              src = root;
              filter =
                path: _type:
                let
                  rootStr = toString root;
                  pathStr = toString path;
                  rel = if pathStr == rootStr then "." else lib.removePrefix "${rootStr}/" pathStr;
                  top = builtins.head (lib.splitString "/" rel);
                in
                rel == "."
                || builtins.elem rel [
                  "flake.nix"
                  "flake.lock"
                ]
                || builtins.elem top [
                  "modules"
                  "steamdeck-packages"
                ];
            };
            target = "nix-config";
          }
        ];
      };

      users.users.${installerUser} = {
        isNormalUser = true;
        description = "Steam Deck Installer User";
        extraGroups = [
          "wheel"
          "networkmanager"
          "audio"
          "video"
        ];
        password = "jovian";
        shell = pkgs.bash;
      }
      // lib.optionalAttrs isDualBoot {
        uid = 1000;
      };

      users.groups.${installerUser} = lib.optionalAttrs isDualBoot {
        gid = 1000;
      };

      security.sudo.wheelNeedsPassword = false;

      services.openssh.settings = {
        PermitRootLogin = lib.mkForce "yes";
        PermitEmptyPasswords = "yes";
      };
      services.flatpak.enable = lib.mkForce false;

      environment.etc.${diskConfigFile}.text = lib.readFile diskConfigPath;

      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.loader.grub.enable = lib.mkForce false;
      boot.loader.grub.efiSupport = lib.mkForce false;

      documentation.enable = false;
      documentation.nixos.enable = false;
    };
in
{
  flake.modules.nixos.EmeraldEcho = mkEmeraldSystemModule "dual";
  flake.modules.nixos.EmeraldEchoDualBoot = mkEmeraldSystemModule "dual";
  flake.modules.nixos.EmeraldEchoSingleBoot = mkEmeraldSystemModule "single";
  flake.modules.nixos.EmeraldEchoBootstrap = mkEmeraldBootstrapModule "dual";
  flake.modules.nixos.EmeraldEchoDualBootBootstrap = mkEmeraldBootstrapModule "dual";
  flake.modules.nixos.EmeraldEchoSingleBootBootstrap = mkEmeraldBootstrapModule "single";
  flake.modules.nixos.EmeraldEchoInstaller = mkEmeraldInstallerModule "dual";
  flake.modules.nixos.EmeraldEchoDualBootInstaller = mkEmeraldInstallerModule "dual";
  flake.modules.nixos.EmeraldEchoSingleBootInstaller = mkEmeraldInstallerModule "single";

  flake.modules.homeManager.EmeraldEcho = mkEmeraldHomeModule;

  flake.nixosConfigurations = lib.mkMerge [
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEcho")
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoDualBoot")
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoSingleBoot")
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoBootstrap")
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoDualBootBootstrap")
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoSingleBootBootstrap")
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoInstaller")
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoDualBootInstaller")
    (inputs.self.lib.mkNixos "x86_64-linux" "EmeraldEchoSingleBootInstaller")
  ];
}
