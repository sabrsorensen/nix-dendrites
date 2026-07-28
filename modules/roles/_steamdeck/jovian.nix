{ inputs, ... }:
let
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.jovian-nixos.nixosModules.default ];
      config = lib.mkIf config.my.host.is.steamdeck {
        networking = {
          networkmanager.enable = true;
          firewall.enable = true;
        };
        jovian = {
          devices.steamdeck.enable = true;
          hardware.has.amd.gpu = true;
          steam = {
            autoStart = true;
            enable = true;
            user = "sam";
            # Jovian validates this against installed display-manager sessions.
            # Enable Plasma below so Desktop Mode is both valid and available.
            desktopSession = "plasma";
            updater.splash = "jovian";
            environment = {
              LANG = "en_US.UTF-8";
              LC_ALL = "en_US.UTF-8";
              FREETYPE_PROPERTIES = "truetype:interpreter-version=38";
            };
          };
        };
        programs.steam = {
          remotePlay.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
        };
        programs.partition-manager.enable = true;
        services.desktopManager.plasma6.enable = true;
        services.xserver.xkb = {
          layout = "us";
          variant = "dvorak";
        };
        nix.settings = {
          auto-optimise-store = true;
          builders-use-substitutes = true;
          cores = 0;
          download-buffer-size = 1073741824;
          extra-substituters = [ "https://jovian-experiments.cachix.org" ];
          extra-trusted-public-keys = [
            "jovian-experiments.cachix.org-1:lwPS3KgK5sJlI2B9KBY4VpbWNGbAjCcKVkUyqfzVrJE="
          ];
          # The Steam Deck has limited storage, so retain fewer build outputs.
          keep-derivations = lib.mkForce false;
          keep-outputs = lib.mkForce false;
          max-jobs = "auto";
        };
        programs.nh.clean.extraArgs = lib.mkForce "--keep-since 2d --keep 2";
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "steam"
            "steam-unwrapped"
          ];
        environment = {
          plasma6.excludePackages = with pkgs.kdePackages; [
            elisa
            kate
          ];
          systemPackages = with pkgs; [
            age
            curl
            gh
            git
            htop
            jupiter-dock-updater-bin
            kdePackages.kcalc
            kdePackages.krdc
            lm_sensors.bin
            maliit-keyboard
            nix-output-monitor
            nix-tree
            openssh
            rsync
            sops
            ssh-to-age
            steamdeck-firmware
            vim
            wget
          ];
          variables = {
            FONTCONFIG_PATH = "/run/current-system/sw/etc/fonts";
            FONTCONFIG_FILE = "/run/current-system/sw/etc/fonts/fonts.conf";
          };
        };
        fonts = {
          fontconfig.enable = true;
          packages = with pkgs; [
            nerd-fonts.hack
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            source-han-mono
            source-han-sans
            source-han-serif
          ];
        };
        time.timeZone = lib.mkForce "America/Denver";
        i18n.defaultLocale = "en_US.UTF-8";
        users.groups = {
          input = { };
          plugdev = { };
        };
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = lib.mkDefault false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
          };
        };
        services.flatpak.enable = true;
        programs.kdeconnect.enable = lib.mkIf (
          !builtins.elem "bootstrap" config.my.host.tags && !builtins.elem "installer" config.my.host.tags
        ) true;
        services.flatpak.packages =
          lib.mkIf
            (!builtins.elem "bootstrap" config.my.host.tags && !builtins.elem "installer" config.my.host.tags)
            [
              "io.github.Geocld.XStreamingDesktop"
              "io.github.unknownskl.greenlight"
            ];
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
        };
        systemd.services = {
          "drkonqi-coredump-launcher@".enable = false;
          "drkonqi-coredump-processor@".enable = false;
        };
        systemd.settings.Manager.DefaultLimitCORE = 0;
        systemd.user.services.gamescope-session = {
          restartIfChanged = lib.mkForce false;
          stopIfChanged = lib.mkForce false;
        };
      };
    };
in
module
