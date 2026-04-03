{
  inputs,
  lib,
  ...
}:
let
  shared = import ./_emeraldecho/shared.nix { inherit inputs; };

  mkEmeraldSystemModule =
    bootMode:
    { config, pkgs, ... }:
    let
      enableNixRemote = !(config.wsl.enable or false) && config ? sops && config.sops.secrets ? hashed_password;
    in
    {
      imports = with inputs.self.modules.nixos; [
        sam
        system-cli
        disko
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.jovian-nixos.nixosModules.default
        ./_decky/decky-plugins.nix
        (import ./_decky/steamdeck-decky.nix { steamUser = shared.steamUser; })
        ./_decky/steamdeck-plugins.nix
        (import ./_steamdeck/steamdeck-hw-config.nix bootMode)
        (import ./_steamdeck/steamdeck-steam.nix { steamUser = shared.steamUser; })
        ./_steamdeck/steamdeck-system.nix
      ];

      users.users.${shared.steamUser} = {
        isNormalUser = true;
        extraGroups = shared.steamUserExtraGroups;
        uid = lib.mkForce 1000;
        hashedPasswordFile = config.sops.secrets.hashed_password.path;
        openssh.authorizedKeys.keyFiles = shared.steamUserAuthorizedKeys;
      };

      users.groups.${shared.steamUser}.gid = lib.mkForce 1000;

      users.users.nix-remote = lib.mkIf enableNixRemote {
        openssh.authorizedKeys.keyFiles = shared.nixRemoteAuthorizedKeys;
      };

      home-manager.users.${shared.steamUser}.imports = [
        inputs.self.modules.homeManager.EmeraldEcho
      ];

      networking.firewall.allowedTCPPorts = [
        1400
        3400
        24800
      ];
      networking.firewall.allowedUDPPorts = [ 24800 ];

      environment.systemPackages = map (name: pkgs.${name}) shared.deckSystemPackages;

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
        (import ./_steamdeck/steamdeck-steam.nix { steamUser = shared.steamUser; })
        ./_steamdeck/steamdeck-system.nix
      ];

      users.users.${shared.steamUser} = {
        isNormalUser = true;
        extraGroups = shared.steamUserExtraGroups;
        hashedPasswordFile = lib.mkForce null;
        initialPassword = "jovian";
      }
      // lib.optionalAttrs isDualBoot {
        uid = lib.mkForce 1000;
      };

      users.groups.${shared.steamUser} = lib.optionalAttrs isDualBoot {
        gid = lib.mkForce 1000;
      };

      home-manager.users.${shared.steamUser} = {
        home.username = shared.steamUser;
        home.homeDirectory = "/home/${shared.steamUser}";
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
        (import ./_steamdeck/steamdeck-steam.nix { steamUser = shared.steamUser; })
        ./_steamdeck/steamdeck-system.nix
      ];

      nixpkgs.config.allowUnfree = true;

      networking.hostName = lib.mkForce "jovian-installer";

      users.users.nixos.enable = lib.mkForce false;
      services.displayManager.autoLogin.user = lib.mkForce shared.installerUser;
      jovian = {
        decky-loader.enable = lib.mkForce false;
        steam = {
          autoStart = lib.mkForce false;
          user = lib.mkForce shared.installerUser;
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
              src = shared.root;
              filter =
                path: _type:
                let
                  rootStr = toString shared.root;
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

      users.users.${shared.installerUser} = {
        isNormalUser = true;
        description = "Steam Deck Installer User";
        extraGroups = shared.steamUserExtraGroups;
        password = "jovian";
        shell = pkgs.bash;
      }
      // lib.optionalAttrs isDualBoot {
        uid = 1000;
      };

      users.groups.${shared.installerUser} = lib.optionalAttrs isDualBoot {
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

  flake.modules.homeManager.EmeraldEcho = {
    imports = with inputs.self.modules.homeManager; [
      firefox
      vscode
      ./_steamdeck/steamdeck-home.nix
    ];
  };

  flake.homeConfigurations."deck@EmeraldEcho" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      overlays = [ inputs.self.overlays.default ];
      config.allowUnfree = true;
    };
    extraSpecialArgs = {
      osConfig = shared.deckSteamOsConfig;
    };
    modules = [
      inputs.self.modules.homeManager.home
      inputs.self.modules.homeManager.sam-secrets
      inputs.self.modules.homeManager.EmeraldEcho
      (
        { pkgs, lib, ... }:
        {
          home.username = "deck";
          home.homeDirectory = "/home/deck";
          home.stateVersion = "26.05";
          home.packages = map (name: pkgs.${name}) shared.deckSteamHomePackages;
          home.activation.setupSteamLibraryMount =
            lib.hm.dag.entryAfter [ "writeBoundary" ] shared.setupSteamLibraryMount;
        }
      )
    ];
  };

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
