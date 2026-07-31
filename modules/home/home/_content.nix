{
  inputs,
  ...
}:
{
  flake-file.inputs.gitignore = {
    url = "github:hyrfilm/gitignore";
    flake = false;
  };

  # Base managed Home Manager profile. Program-specific Home Manager settings
  # are broadcast by sibling modules such as home-git, home-fish, and home-ssh.
  flake.modules.nixos.sam-home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      host = config.my.host;
      username = host.home.username;
      homeDirectory = host.home.homeDirectory;
    in
    lib.mkIf host.home.enable {
      home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];

      home-manager.users.${username} = {
        imports = [
          inputs.nix-index-database.homeModules.nix-index
        ]
        ++ lib.optionals (host.platform == "wsl") [
          "${inputs.nix-work-secrets}/modules/sam-secrets-private.nix"
        ];

        home = {
          username = lib.mkForce username;
          homeDirectory = lib.mkForce homeDirectory;
          stateVersion = "26.05";
          packages =
            with pkgs;
            [
              cowsay
              fortune
              jq
              lolcat
              mediainfo
              nerd-fonts.caskaydia-cove
              comma
              (runCommandLocal "gitignore" { } ''
                install -Dm755 ${inputs.gitignore}/gitignore "$out/bin/gitignore"
              '')
            ]
            ++ lib.optionals host.features.homeGuiPackages [
              clementine
              discord
              ferdium
              plex-desktop
              qdirstat
              signal-desktop
              vlc
            ];
          sessionVariables.XDG_CONFIG_HOME = lib.mkDefault "$HOME/.config";
        };

        programs = {
          home-manager.enable = true;
          nix-index = {
            enable = true;
            enableBashIntegration = true;
            enableFishIntegration = true;
            enableZshIntegration = true;
          };
          # Avoid generating per-user man-cache/manpath state on WSL.
          man.generateCaches = false;
          command-not-found.enable = false;
        };
      };
    };
}
