{
  inputs,
  lib,
  self,
  ...
}:

let
  username = "sam";
in
{
  flake.modules = lib.mkMerge [
    (self.factory.user username true)
    {
      nixos."${username}" = {
        imports =
          (with inputs.self.modules.nixos; [
            virtualisation
            kde
            appimage
            deskflow
            flatpak
            threedprinter
            minecraft
            steam
          ])
          ++ [
            "${inputs.nix-secrets}/modules/system-secrets-private.nix"
          ];

        users.users."${username}" = {
          group = username;
        };
        programs.fish.enable = true;
      };
    }

    {
      homeManager."${username}" =
        { pkgs, ... }:
        {
          imports =
            (with inputs.self.modules.homeManager; [
              bash
              fish
              git
              github-cli
              gpg
              sam-git
              sam-secrets
              ssh
              starship
              system-desktop
              tmux
              vim
            ])
            ++ [
              "${inputs.nix-secrets}/modules/sam-syncthing-private.nix"
              "${inputs.nix-secrets}/modules/sam-secrets-private.nix"
            ];
          home.username = lib.mkDefault "sam";
          home.homeDirectory = lib.mkDefault "/home/sam";
          home.sessionVariables = {
            XDG_CONFIG_HOME = "$HOME/.config";
          };
          home.packages = with pkgs; [
            nerd-fonts.caskaydia-cove

            bitwarden-desktop
            clementine
            deskflow
            discord
            ferdium
            mediainfo
            noson
            p7zip
            plex-desktop
            rclone
            signal-desktop
            vlc
          ];
          # Let Home Manager install and manage itself.
          programs.home-manager.enable = true;

          # Less documentation, but really saves on build time.
          programs.man.generateCaches = false;
        };
    }
  ];
}
