{
  homeModules,
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
      deployment = config.my.deployment;
      username = host.home.username;
      homeDirectory = host.home.homeDirectory;
      hasLocalFlake = deployment.localFlakePath != null;
      canDeployRemotely = deployment.canDeployRemotely && hasLocalFlake;
      domain = builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile "${inputs.nix-secrets}/domain.txt"
      );
    in
    lib.mkIf host.home.enable {
      home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];

      home-manager.users.${username} = {
        imports =
          homeModules
          ++ lib.optionals (host.platform == "wsl") [
            "${inputs.nix-work-secrets}/modules/sam-secrets-private.nix"
            "${inputs.nix-work-secrets}/modules/codex-projects-private.nix"
          ];

        my.features = {
          bash = true;
          atuin = host.features.atuin;
          beets = host.features.beets;
          bitwarden = host.features.bitwarden;
          demlo = host.features.demlo;
          direnv = true;
          firefox = host.features.firefox;
          "github-cli" = true;
          fish = true;
          git = true;
          gpg = true;
          gdrive = host.features.gdrive;
          herdr = host.features.codex || host.features.claudeCode;
          lazyvim = host.features.lazyvim;
          mcpCommon = host.features.mcpCommon;
          "nix-index" = true;
          noson = host.features.noson;
          office = host.features.office;
          personalMcp = host.features.personalMcp;
          persistence = host.features.persistenceHome;
          sops = host.platform != "wsl";
          starship = true;
          steamdeck = host.platform == "steamdeck";
          syncthing = builtins.elem host.name [
            "Kamino"
            "ZaphodBeeblebrox"
            "EmeraldEcho"
          ];
          ssh = true;
          tmux = true;
          vim = true;
          wslFish = host.platform == "wsl";
          wslCodex = host.platform == "wsl" && host.features.codex;
          wslWorkHome = host.platform == "wsl";
          wslVscode = host.platform == "wsl";
          vscode = host.features.vscode;
          claudeCode = host.features.claudeCode;
          codex = host.features.codex;
        };
        my.bash.isSteamDeck = host.platform == "steamdeck";
        my.fish = {
          isWsl = host.platform == "wsl";
          deploy = {
            enable = canDeployRemotely;
            path = deployment.localFlakePath;
            inherit domain;
            inhibitSleep = deployment.sleepy;
          };
          localFlake = {
            enable = hasLocalFlake;
            path = deployment.localFlakePath;
            configurationName = lib.toLower host.name;
            inhibitSleep = deployment.sleepy;
          };
          local.enable = true;
          rpi.enable = host.is.rpi;
          steamdeck.enable = host.platform == "steamdeck";
        };
        my.atuin.domain = builtins.replaceStrings [ "\n" ] [ "" ] (
          builtins.readFile "${inputs.nix-secrets}/domain.txt"
        );
        my.features.konsole = host.features.konsole;
        my.features.plasma = host.features.plasma;
        my.gpg = {
          isGui = host.features.gui;
          isWsl = host.platform == "wsl";
          secretRoot = inputs.nix-secrets;
        };
        my.gdrive = {
          secretFile = "${inputs.nix-secrets}/rclone/gdrive.yaml";
          tokenName = "rclone/gdrive/${lib.strings.toLower host.name}_token";
        };
        my.ssh = {
          domain = builtins.replaceStrings [ "\n" ] [ "" ] (
            builtins.readFile "${inputs.nix-secrets}/domain.txt"
          );
          hostName = host.name;
          canDeployRemotely = config.my.deployment.canDeployRemotely;
        };
        my.sops = {
          homeDirectory = homeDirectory;
          isManagedPersonal = host.platform != "wsl";
        };
        my.syncthingClient = {
          hostName = host.name;
          devices = config.my.syncthing.devices;
          folders = config.my.syncthing.folders;
          tray.enable = host.name != "EmeraldEcho";
          isSteamDeck = host.platform == "steamdeck";
        };
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
          # Avoid generating per-user man-cache/manpath state on WSL.
          man.generateCaches = false;
          command-not-found.enable = false;
        };
      };
    };
}
