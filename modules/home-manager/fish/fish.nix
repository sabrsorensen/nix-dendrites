{
  flake.modules.homeManager.fish =
    {
      config,
      inventory ? { },
      lib,
      osConfig ? { },
      pkgs,
      ...
    }:
    let
      hostCfg = if osConfig ? my && osConfig.my ? host then osConfig.my.host else config.my.host;
      nixFlakePath = if hostCfg.deploy ? localFlakePath then hostCfg.deploy.localFlakePath else null;
      deployLocalUser = if hostCfg.deploy ? localUser then hostCfg.deploy.localUser else null;
      localDomain =
        if osConfig ? systemConstants && osConfig.systemConstants ? domain then
          osConfig.systemConstants.domain
        else
          hostCfg.domain;
      pingTargetFallback =
        if localDomain != null && localDomain != "" then
          ''
            set ping_host "$target_host.${localDomain}"
          ''
        else
          ''
            set ping_host "$target_host"
          '';

      # Feature flags based on host type
      isWorkstation = hostCfg.roles.workstation;
      isPi = hostCfg.roles.rpi;
      isDeck = hostCfg.roles.steamdeck;
      isWsl = hostCfg.roles.wsl;
      hasPodman = osConfig ? virtualisation && osConfig.virtualisation ? podman && (osConfig.virtualisation.podman.enable or false);
      sleepySystem = hostCfg.deploy.sleepy;

      hasNixFlake = nixFlakePath != null;
      canDeployRemotely = hostCfg.deploy.canDeployRemotely && hasNixFlake;
      secureDeployRoleUnits = {
        "blocky-dns" = [
          "blocky"
          "coredns"
        ];
        "dhcp-primary" = [ "dhcp-coredns-kea" ];
        "dhcp-standby" = [ "dhcp-failover.timer" ];
      };
      expandServiceRoles =
        roles: lib.unique (lib.concatLists (map (role: secureDeployRoleUnits.${role} or [ ]) roles));
      secureDeployConfigCases = lib.concatStrings (
        lib.mapAttrsToList (
          name: peer:
          if peer ? deploy && peer.deploy ? secure then
            let
              secureCfg = peer.deploy.secure;
              peerCfg = inventory.${secureCfg.peerName} or { };
              renderedSecureCfg = secureCfg // {
                peerServices = expandServiceRoles (peerCfg.serviceRoles or [ ]);
                targetServices = expandServiceRoles (peer.serviceRoles or [ ]);
              };
            in
            ''
              case ${name}
                  printf '%s\n' '${builtins.toJSON renderedSecureCfg}'
            ''
          else
            ""
        ) inventory
      );
      remoteDeployMethod =
        let
          cases = lib.concatStrings (
            lib.mapAttrsToList (
              name: peer:
              lib.optionalString (peer ? deploy && peer.deploy ? remoteMethod) ''
                case ${name}
                    echo ${peer.deploy.remoteMethod}
              ''
            ) inventory
          );
        in
        "switch $argv[1]\n${cases}    case '*'\n        echo switch\nend";
      mkNhSwitchRemote =
        {
          upgrade ? false,
        }:
        if canDeployRemotely then
          let
            upgradeFlag = if upgrade then "--update" else "";
          in
          ''
            set target_host_lower (string lower $argv[1])
            inhibitSleep nh os switch ${nixFlakePath} -H $argv[1] --target-host "nix-$target_host_lower" ${upgradeFlag} --keep-going $argv[2..-1]
          ''
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
            ${pingTargetFallback}
            set ssh_ping_host (ssh -G $target_host 2>/dev/null | string match -r "^[Hh]ostname " | string replace -r "^[Hh]ostname " "")

            if test -n "$ssh_ping_host"
                set ping_host $ssh_ping_host
            end

            echo "🔨 Building $target_host locally before waiting for it to come online..."
            inhibitSleep nh os build ${nixFlakePath} -H $target_host ${upgradeFlag} --keep-going $argv[2..-1]
            or return $status

            if command -sq notify-send
                notify-send "Steam Deck build complete" "Turn on $target_host. Deployment will continue after it responds to ping."
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
        plugins = [
          {
            name = "fish-ssh-agent";
            src = pkgs.fetchFromGitHub {
              owner = "danhper";
              repo = "fish-ssh-agent";
              rev = "f10d95775352931796fd17f54e6bf2f910163d1b";
              hash = "sha256-cFroQ7PSBZ5BhXzZEKTKHnEAuEu8W9rFrGZAb8vTgIE=";
            };
          }
          {
            name = "to-fish";
            src = pkgs.fetchFromGitHub {
              owner = "joehillen";
              repo = "to-fish";
              rev = "b94c2e5756b4646051fe64ad8cd36eda33405f8a";
              hash = "sha256-jQGYFON13XhjX+Xrnd8kglco8xRJ9G7kkGmswtuEgZw=";
            };
          }
        ];
        #shellInit = ''
        #'';
        #shellInitLast = ''
        #'';
        interactiveShellInit = ''
          # Load greeting function
          source ${./functions/fish_greeting.fish}

          # Load secure-deploy function (available on all deployment-capable hosts)
          ${lib.optionalString canDeployRemotely ''
            set -gx DENDRITIC_FLAKE_PATH ${lib.escapeShellArg nixFlakePath}
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
            set inhibit_user ${lib.escapeShellArg (if deployLocalUser != null then deployLocalUser else "")}
            if test -z "$inhibit_user"
                set inhibit_user $USER
            end
            systemd-inhibit --what=shutdown:sleep:idle:handle-power-key:handle-suspend-key:handle-hibernate-key:handle-lid-switch --who="$inhibit_user" --why=nixos-rebuild --mode=block $argv
          '';

          # === WORKSTATION FUNCTIONS (development/testing) ===
          updateFirefoxCustomAddons =
            if isWorkstation && hasNixFlake then
              ''
                nix-shell -E 'let
                  flake = builtins.getFlake "${nixFlakePath}";
                  pkgs = import flake.inputs.nixpkgs {
                    system = builtins.currentSystem;
                    overlays = [ flake.inputs.nur.overlays.default flake.outputs.overlays.default ];
                    config.allowUnfree = true;
                  };
                in pkgs.mkShell {
                  buildInputs = [ pkgs.nur.repos.rycee.mozilla-addons-to-nix ];
                }' --run 'mozilla-addons-to-nix ${nixFlakePath}/modules/home-manager/firefox/_custom_firefox_addons.json ${nixFlakePath}/modules/home-manager/firefox/_custom_firefox_addons.nix'
              ''
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
          vscodeSyncWindows = if isWsl then "vscode-sync-windows" else null;
          vsw = if isWsl then "vscodeSyncWindows" else null;
          vscodeSyncWindowsExtensions = if isWsl then "vscode-sync-windows --install-extensions" else null;
          vswe = if isWsl then "vscodeSyncWindowsExtensions" else null;

          # Remote deployment functions - only on workstations
          nhSwitchRemote = mkNhSwitchRemote { };
          nhSwitchUpgradeRemote = mkNhSwitchRemote { upgrade = true; };
          nhBuildThenSwitchRemote = mkNhBuildThenSwitchRemote { };
          nhBuildThenSwitchUpgradeRemote = mkNhBuildThenSwitchRemote { upgrade = true; };
          remoteDeployMethod = if canDeployRemotely then remoteDeployMethod else null;
          secureDeployConfig =
            if canDeployRemotely then
              ''
                switch $argv[1]
                ${secureDeployConfigCases}    case '*'
                        return 1
                end
              ''
            else
              null;

          nhsr =
            if canDeployRemotely then
              ''
                switch (remoteDeployMethod $argv[1])
                    case secure
                        secure-deploy $argv
                    case build-then-switch
                        nhBuildThenSwitchRemote $argv
                    case '*'
                        nhSwitchRemote $argv
                end
              ''
            else
              null;
          nhsur =
            if canDeployRemotely then
              ''
                switch (remoteDeployMethod $argv[1])
                    case secure
                        secure-deploy --upgrade $argv
                    case build-then-switch
                        nhBuildThenSwitchUpgradeRemote $argv
                    case '*'
                        nhSwitchUpgradeRemote $argv
                end
              ''
            else
              null;

          # Secure deployment with safety checks (for Naboo/Nevarro)
          secureDeployChecked =
            if canDeployRemotely then
              ''
                if test (remoteDeployMethod $argv[1]) = "build-then-switch"
                    echo "Use nhsur for Steam Deck deployment"
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
              ''
                set target_host_lower (string lower $argv[1])
                inhibitSleep nh os switch ${nixFlakePath} -H $argv[1] --target-host "nix-$target_host_lower" --update --keep-going $argv[2..-1]
              ''
            else
              null;

          # === MAINTENANCE FUNCTIONS ===
          cleanGenerations =
            let
              runCleanCommand = command: if sleepySystem then "inhibitSleep ${command}" else command;
            in
            if isWorkstation || isPi || isWsl || hostCfg.roles.server || isDeck then
              ''
                echo "Cleaning user profile generations..."
                nix-collect-garbage -d
                or return $status

                echo "Cleaning system and root generations..."
                ${runCleanCommand "sudo nix-collect-garbage -d"}
                or return $status

                echo "Collecting unused store paths..."
                ${runCleanCommand "sudo nix store gc"}
                or return $status

                echo "Optimizing store hard links..."
                ${runCleanCommand "sudo nix store optimise"}
                or return $status

                if test -x /run/current-system/bin/switch-to-configuration
                    if ${if isWsl then "false" else "true"}
                        echo "Refreshing boot entries..."
                        ${runCleanCommand "sudo /run/current-system/bin/switch-to-configuration boot"}
                        or return $status
                    else
                        echo "Skipping boot entry refresh on WSL."
                    end
                end
              ''
            else
              null;

          # === WSL-SPECIFIC FUNCTIONS ===
          choco = if isWsl then "choco.exe $argv" else null;
          wsl = if isWsl then "wsl.exe $argv" else null;

          # === PODMAN / OCI CONTAINER FUNCTIONS ===
          podmanSystem = if hasPodman then "sudo podman $argv" else null;
          pds = if hasPodman then "podmanSystem" else null;

          podmanSystemPs =
            if hasPodman then
              "sudo podman ps --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'"
            else
              null;
          podmanSystemPsAll =
            if hasPodman then
              "sudo podman ps -a --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'"
            else
              null;
          podmanUserPs =
            if hasPodman then
              "podman ps --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'"
            else
              null;
          podmanUserPsAll =
            if hasPodman then
              "podman ps -a --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.RunningFor}}'"
            else
              null;

          pps = if hasPodman then "podmanSystemPs" else null;
          ppsa = if hasPodman then "podmanSystemPsAll" else null;
          ppu = if hasPodman then "podmanUserPs" else null;
          ppua = if hasPodman then "podmanUserPsAll" else null;
          dps = if hasPodman then "podmanSystemPsAll" else null;

          podmanUnitName =
            if hasPodman then
              ''
                set name $argv[1]
                if test -z "$name"
                    return 1
                end

                if string match -q 'podman-*.service' -- "$name"
                    echo "$name"
                else if string match -q '*.service' -- "$name"
                    echo "podman-"(string replace -r '\.service$' "" -- "$name")".service"
                else
                    echo "podman-$name.service"
                end
              ''
            else
              null;

          podmanContainerName =
            if hasPodman then
              ''
                set unit (podmanUnitName $argv[1])
                or return 1
                string replace -r '^podman-(.*)\.service$' '$1' -- "$unit"
              ''
            else
              null;

          podmanServices =
            if hasPodman then
              "systemctl list-units --type=service --all 'podman-*.service'"
            else
              null;
          pcs = if hasPodman then "podmanServices" else null;

          podmanServiceStatus =
            if hasPodman then
              ''
                for name in $argv
                    set unit (podmanUnitName $name)
                    or return 1
                    sudo systemctl status $unit
                end
              ''
            else
              null;
          podmanServiceLogs =
            if hasPodman then
              ''
                for name in $argv
                    set unit (podmanUnitName $name)
                    or return 1
                    sudo journalctl -u $unit -f
                end
              ''
            else
              null;
          podmanServicePull =
            if hasPodman then
              ''
                if test (count $argv) -eq 0
                    echo "Usage: podmanServicePull <container|service> [...]"
                    return 1
                end

                for name in $argv
                    set container (podmanContainerName $name)
                    or return 1
                    set image (sudo podman inspect --format '{{.ImageName}}' $container 2>/dev/null)
                    if test -z "$image"
                        echo "No existing rootful container found for $name" >&2
                        return 1
                    end

                    echo "Pulling $image"
                    sudo podman pull $image
                    or return $status
                end
              ''
            else
              null;
          podmanServiceUp =
            if hasPodman then
              ''
                if test (count $argv) -eq 0
                    echo "Usage: podmanServiceUp <container|service> [...]"
                    return 1
                end

                for name in $argv
                    set unit (podmanUnitName $name)
                    or return 1
                    if sudo systemctl is-active --quiet $unit
                        sudo systemctl restart $unit
                    else
                        sudo systemctl start $unit
                    end
                    or return $status
                end
              ''
            else
              null;

          pcss = if hasPodman then "podmanServiceStatus" else null;
          pcsl = if hasPodman then "podmanServiceLogs" else null;
          pcp = if hasPodman then "podmanServicePull" else null;
          pcu = if hasPodman then "podmanServiceUp" else null;
          dcp = if hasPodman then "podmanServicePull" else null;
          dcu = if hasPodman then "podmanServiceUp" else null;
        };
      };
    };
}
