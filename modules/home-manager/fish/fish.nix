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

      nixFlakePath = "~/src/nix-dendrites/";

      # Feature flags based on host type
      isWorkstation = hostType == "workstation";
      isPi = hostType == "pi";
      isDeck = hostType == "deck";
      isServer = hostType == "server";
      isAtlas = hostname == "AtlasUponRaiden";
      isWsl = hostname == "NixOS-WSL";
      sleepySystem = builtins.elem hostname [
        "EmeraldEcho"
        "Kamino"
        "ZaphodBeeblebrox"
      ];

      hasNixFlake = isWorkstation || isServer;
      canDeployRemotely = (isWorkstation || isServer) && !isWsl;
      mkNhSwitchRemote =
        {
          upgrade ? false,
        }:
        if canDeployRemotely then
          let
            targetHost = "nix-(string lower $argv[1])";
            upgradeFlag = if upgrade then "--update" else "";
          in
          "inhibitSleep nh os switch ${nixFlakePath} -H $argv[1] --target-host ${targetHost} ${upgradeFlag} --keep-going $argv[2..-1]"
        else
          null;
      mkNhBuildThenSwitchRemote =
        {
          upgrade ? false,
        }:
        if canDeployRemotely then
          let
            upgradeFlag = if upgrade then "--update" else "";
          in
          ''
            set target_host $argv[1]

            if test -z "$target_host"
                echo "Usage: <command> <target_host> [additional_args...]"
                return 1
            end

            set target_host_lower (string lower $target_host)
            set switch_target_host "nix-$target_host_lower"
            set ping_host (ssh -G $target_host 2>/dev/null | string match -r "^hostname " | string replace "hostname " "")

            if test -z "$ping_host"
                echo "Failed to resolve ping target for $target_host from SSH config"
                return 1
            end

            echo "🔨 Building $target_host locally before waiting for it to come online..."
            inhibitSleep nh os build ${nixFlakePath} -H $target_host ${upgradeFlag} --keep-going $argv[2..-1]
            or return $status

            if command -sq notify-send
                notify-send "EmeraldEcho build complete" "Turn on $target_host. Deployment will continue after it responds to ping."
            end

            echo "Build completed for $target_host."
            echo "Turn on $target_host, then press Enter to start waiting for network reachability."
            read

            echo "Waiting for $target_host at $ping_host to respond to ping..."
            while not ping -c 1 -W 1 $ping_host >/dev/null 2>&1
                sleep 5
            end

            echo "$target_host is reachable. Starting remote switch..."
            inhibitSleep nh os switch ${nixFlakePath} -H $target_host --target-host $switch_target_host ${upgradeFlag} --keep-going $argv[2..-1]
          ''
        else
          null;

    in
    {
      home.packages = with pkgs; [
        cowsay
        fortune
        jq
        lolcat
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

          # Load secure-deploy function (available on all deployment-capable hosts)
          ${lib.optionalString canDeployRemotely ''
            source ${./functions/secure-deploy.fish}
          ''}

          # Load Pi-specific functions on Pi hosts
          ${lib.optionalString isPi ''
            source ${./functions/pi_functions.fish}
          ''}

          # Load Deck-specific functions on Steam Deck
          ${lib.optionalString isDeck ''
            source ${./functions/deck_functions.fish}
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
          fetchFfAddons =
            if isWorkstation then
              "python3 ${nixFlakePath}/modules/home-manager/firefox/fetch_firefox_addons.py ${nixFlakePath}/modules/home-manager/firefox/firefox_addons.json"
            else
              null;

          # === DEPLOYMENT FUNCTIONS (workstation only) ===
          nhSwitch =
            if hasNixFlake then
              if sleepySystem then
                "inhibitSleep nh os switch ${nixFlakePath} --keep-going"
              else
                "nh os switch ${nixFlakePath} --keep-going"
            else
              null;
          nhs = if hasNixFlake then "nhSwitch" else null;
          nhSwitchUpgrade =
            if hasNixFlake then
              if sleepySystem then
                "inhibitSleep nh os switch ${nixFlakePath} --update --keep-going"
              else
                "nh os switch ${nixFlakePath} --update --keep-going"
            else
              null;
          nhsu = if hasNixFlake then "nhSwitchUpgrade" else null;

          # Remote deployment functions - only on workstations
          nhSwitchRemote = mkNhSwitchRemote { };
          nhSwitchUpgradeRemote = mkNhSwitchRemote { upgrade = true; };
          nhBuildThenSwitchRemote = mkNhBuildThenSwitchRemote { };
          nhBuildThenSwitchUpgradeRemote = mkNhBuildThenSwitchRemote { upgrade = true; };

          nhsr =
            if canDeployRemotely then
              ''
                if test "$argv[1]" = "Naboo" -o "$argv[1]" = "Nevarro"
                    secure-deploy $argv
                else if test "$argv[1]" = "EmeraldEcho"
                    nhBuildThenSwitchRemote $argv
                else
                    nhSwitchRemote $argv
                end
              ''
            else
              null;
          nhsur =
            if canDeployRemotely then
              ''
                if test "$argv[1]" = "Naboo" -o "$argv[1]" = "Nevarro"
                    secure-deploy --upgrade $argv
                else if test "$argv[1]" = "EmeraldEcho"
                    nhBuildThenSwitchUpgradeRemote $argv
                else
                    nhSwitchUpgradeRemote $argv
                end
              ''
            else
              null;

          # Secure deployment with safety checks (for Naboo/Nevarro)
          secureDeployChecked =
            if canDeployRemotely then
              ''
                if test "$argv[1]" = "EmeraldEcho"
                    echo "Use nhsur for EmeraldEcho deployment"
                    return 1
                else
                    secure-deploy --upgrade $argv
                end
              ''
            else
              null;

          # Quick unsafe deployment for emergencies (bypasses safety checks)
          nhsur_unsafe =
            if canDeployRemotely then
              "inhibitSleep nh os switch ${nixFlakePath} -H $argv[1] --target-host nix-(string lower $argv[1]) --update --keep-going $argv[2..-1]"
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
