{
  flake.modules.homeManager.fish =
    {
      config,
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hostname = osConfig.networking.hostName;
      # Simplified host detection
      hostType =
        if
          builtins.elem hostname [
            "Kamino"
            "ZaphodBeeblebrox"
            "NixOS-WSL"
          ]
        then
          "workstation"
        else if
          builtins.elem hostname [
            "Naboo"
            "Nevarro"
          ]
        then
          "pi"
        else if builtins.elem hostname [ "EmeraldEcho" ] then
          "deck"
        else if builtins.elem hostname [ "AtlasUponRaiden" ] then
          "server"
        else
          "unknown";

      # Feature flags based on host type
      isWorkstation = hostType == "workstation";
      isPi = hostType == "pi";
      isDeck = hostType == "deck";
      isServer = hostType == "server";
      isAtlas = hostname == "AtlasUponRaiden";
      isWsl = hostname == "NixOS-WSL";

      hasNixFlake = isWorkstation || isServer;
      canDeployRemotely = (isWorkstation || isServer) && !isWsl;
      hasSecretsAccess =
        config ? sops
        && config.sops.secrets ? adguardhome_user
        && config.sops.secrets ? adguardhome_password;

      mkNhSwitchRemote =
        {
          upgrade ? false,
          tail ? false,
        }:
        if canDeployRemotely then
          let
            targetHost = if tail then "nix-(string lower $argv[1])-tail" else "nix-(string lower $argv[1])";
            upgradeFlag = if upgrade then "--update" else "";
          in
          "inhibitSleep nh os switch ~/src/nix/ -H $argv[1] --target-host ${targetHost} ${upgradeFlag} --keep-going $argv[2..-1]"
        else
          null;

    in
    {
      home.packages = with pkgs; [
        jq
      ];

      programs.fish = {
        enable = true;
        #package = pkgs.fish.overrideAttrs (oldAttrs: {
        #  postPatch = (oldAttrs.postPatch or "") + lib.optionalString (pkgs.stdenv.targetPlatform.isAarch64)
        #  ''
        #    rm tests/pexpects/complete.py
        #    rm tests/pexpects/torn_escapes.py
        #    rm tests/checks/noshebang.fish
        #    #find . -regex ".*\(complete\.py)\|noshebang\.fish\|torn_escapes\.py\)" -delete
        #  '';
        #});
        generateCompletions = true;
        #shellInit = ''
        #'';
        #shellInitLast = ''
        #'';
        interactiveShellInit = ''
          if not functions -q fundle
            eval (curl -sfL https://git.io/fundle-install)
          end
          fundle plugin 'danhper/fish-ssh-agent'
          fundle plugin 'joehillen/to-fish'
          fundle init

          # Load greeting function
          source ${./functions/fish_greeting.fish}

          # Load Pi-specific functions on Pi hosts
          ${lib.optionalString isPi ''
            source ${./functions/pi_functions.fish}
          ''}

          # Load Deck-specific functions on Steam Deck
          ${lib.optionalString isDeck ''
            source ${./functions/deck_functions.fish}
          ''}

          # Load NixOS testing functions on workstations
          ${lib.optionalString hasNixFlake ''
            for file in ${./functions/nix}/*.fish
              source $file
            end
          ''}

          # GPG TTY setup (Home Manager's gpg-agent service handles the rest)
          if command -s gpg > /dev/null
            # Set GPG_TTY for proper pinentry behavior
            set -x GPG_TTY (tty)
          end
        '';
        functions = lib.filterAttrs (_name: value: value != null) {
          # === UNIVERSAL FUNCTIONS (available on all hosts) ===
          ls = "command ls -la --color=auto $argv";

          inhibitSleep = ''
            echo "🔒 Inhibiting sleep for: $argv"
            # Set the terminal title to show the actual command
            echo -ne "\033]0;$argv\007"
            systemd-inhibit --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who=sam --why=nixos-rebuild --mode=block $argv
          '';

          # === WORKSTATION FUNCTIONS (development/testing) ===
          updateFlake = if hasNixFlake then "inhibitSleep nix flake update --flake ~/src/nix/" else null;

          fetchFfAddons =
            if isWorkstation then
              "python3 ~/src/nix/home-manager/firefox/fetch_firefox_addons.py ~/src/nix/home-manager/firefox/firefox_addons.json"
            else
              null;

          # === DEPLOYMENT FUNCTIONS (workstation only) ===
          nhSwitch =
            if hasNixFlake then
              if isWsl then
                "nh os switch ~/src/nix/wsl --keep-going"
              else
                "inhibitSleep nh os switch ~/src/nix/ --keep-going"
            else
              null;
          nhs = if hasNixFlake then "nhSwitch" else null;
          nhSwitchUpgrade =
            if hasNixFlake then
              if isWsl then
                "nh os switch ~/src/nix/wsl --update --keep-going"
              else
                "inhibitSleep nh os switch ~/src/nix/ --update --keep-going"
            else
              null;
          nhsu = if hasNixFlake then "nhSwitchUpgrade" else null;

          # Remote deployment functions - only on workstations
          nhSwitchRemote = mkNhSwitchRemote { };
          nhSwitchRemoteTail = mkNhSwitchRemote { tail = true; };
          nhSwitchUpgradeRemote = mkNhSwitchRemote { upgrade = true; };
          nhSwitchUpgradeRemoteTail = mkNhSwitchRemote {
            upgrade = true;
            tail = true;
          };

          nhsr =
            if canDeployRemotely then
              ''
                if test "$argv[1]" = "Naboo" -o "$argv[1]" = "Nevarro"
                    ~/src/nix/scripts/secure-deploy.fish $argv
                else
                    inhibitSleep nh os switch ~/src/nix -H $argv[1] --target-host nix-(string lower $argv[1]) --keep-going $argv[2..-1]
                end
              ''
            else
              null;
          nhsrt = if canDeployRemotely then "nhSwitchRemoteTail $argv" else null;
          nhsur =
            if canDeployRemotely then
              ''
                if test "$argv[1]" = "Naboo" -o "$argv[1]" = "Nevarro"
                    ~/src/nix/scripts/secure-deploy.fish --upgrade $argv
                else
                    inhibitSleep nh os switch ~/src/nix -H $argv[1] --target-host nix-(string lower $argv[1]) --update --keep-going $argv[2..-1]
                end
              ''
            else
              null;
          nhsurt = if canDeployRemotely then "nhSwitchUpgradeRemoteTail $argv" else null;

          # Secure deployment with safety checks (for Naboo/Nevarro)
          secure-deploy =
            if canDeployRemotely then
              ''
                if test "$argv[1]" = "EmeraldEcho"
                    echo "Use nhsur for EmeraldEcho deployment"
                    return 1
                else
                    ~/src/nix/scripts/secure-deploy.fish --upgrade $argv
                end
              ''
            else
              null;

          # Quick unsafe deployment for emergencies (bypasses safety checks)
          nhsur_unsafe =
            if canDeployRemotely then
              "inhibitSleep nh os switch ~/src/nix/ -H $argv[1] --target-host nix-(string lower $argv[1]) --update --keep-going $argv[2..-1]"
            else
              null;

          # === MAINTENANCE FUNCTIONS (workstation/pi) ===
          cleanGenerations =
            if isWorkstation then
              "inhibitSleep sudo nix-collect-garbage -d && inhibitSleep sudo nix store gc && inhibitSleep sudo /run/current-system/bin/switch-to-configuration boot"
            else if isPi || isWsl then
              "sudo nix-collect-garbage -d && sudo nix store gc && sudo /run/current-system/bin/switch-to-configuration boot"
            else
              null;

          # === WSL-SPECIFIC FUNCTIONS ===
          choco = if isWsl then "choco.exe $argv" else null;
          wsl = if isWsl then "wsl.exe $argv" else null;
        };
      };
    };
}
