{
  inputs,
  lib,
  ...
}:
let
  luksUuid = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/luks/kamino.txt");
in
{
  flake.modules.nixos.Kamino =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = with inputs.self.modules.nixos; [
        sam
        ./_kamino/hardware.nix
        ./_kamino/filesystem.nix
        ./_kamino/network.nix
        ./_kamino/users/sam.nix
        system-desktop
        systemd-boot
        flatpak
        nvidia
        kde
        xserver
      ];

      boot.loader.efi.canTouchEfiVariables = true;
      boot.initrd.luks.devices."luks-${luksUuid}".device = "/dev/disk/by-uuid/${luksUuid}";
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      nix.buildMachines = [ ];
      nix.distributedBuilds = true;

      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.extraSetup = ''
        find "$out/share/man" \
            -mindepth 1 -maxdepth 1 \
            -not -name "man[1-8]" \
            -exec rm -r "{}" ";"
      '';

      environment.systemPackages = with pkgs; [
        cura-appimage
        hunspell
        hunspellDicts.en_US
        keymapp
        libreoffice-qt
        lshw
        orca-slicer
        prismlauncher
        (python3.withPackages (
          python-pkgs: with python-pkgs; [
            pyqt5
            requests
          ]
        ))
        qt5.qtbase
        qt5.qttools
        qt5.qtwayland
        qt5.qtx11extras
        unstable.uv
        xwayland
      ];

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "discord"
          "keymapp"
          "nvidia-persistenced"
          "nvidia-settings"
          "nvidia-x11"
          "plex-desktop"
          "steam"
          "steam-unwrapped"
        ];

      home-manager.users.sam.imports = [
        inputs.self.modules.homeManager.Kamino
      ];
    };

  flake.modules.homeManager.Kamino = {
    imports = with inputs.self.modules.homeManager; [
      firefox
      konsole
      mcp
      mcp-personal
      no-mans-sky
      vscode
    ];
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "Kamino";
}
