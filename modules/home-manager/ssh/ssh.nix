{
  flake.modules.homeManager.ssh =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    let
      hostname = osConfig.networking.hostName;
      readBuildValue =
        path:
        builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${config.my.buildSecretRoot}/${path}");
      localDomain = readBuildValue "domain.txt";

      # Hosts where we suppress WSL-related blocks
      wslSkipHosts = [ "NixOS-WSL" ];
      nixBlockHosts = [
        "AtlasUponRaiden"
        "Kamino"
        "ZaphodBeeblebrox"
      ];

      mkBaseBlock =
        {
          name,
          user,
          identityFile,
          port ? 22,
          extraSkips ? [ ],
          identitiesOnly ? false,
        }:
        let
          skips = [ name ] ++ wslSkipHosts ++ extraSkips;
        in
        if !(builtins.elem hostname skips) then
          {
            host = name;
            hostname = "${name}.${localDomain}";
            port = port;
            user = user;
            identityFile = identityFile;
          }
          // lib.optionalAttrs identitiesOnly {
            identitiesOnly = true;
          }
        else
          null;

      mkNixBlock =
        {
          name,
          port ? 22,
        }:
        if builtins.elem hostname nixBlockHosts then
          {
            host = "nix-${lib.toLower name}";
            hostname = "${name}.${localDomain}";
            port = port;
            user = "nix-remote";
            identityFile = "~/.ssh/nix_${lib.strings.toLower name}_id_ed25519";
            identitiesOnly = true;
          }
        else
          null;

    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks = lib.filterAttrs (_: v: v != null) ({
          "*" = {
            addKeysToAgent = "yes";
            forwardAgent = true;
            compression = true;
            serverAliveInterval = 0;
            serverAliveCountMax = 3;
            hashKnownHosts = false;
            userKnownHostsFile = "~/.ssh/known_hosts";
          };

          AtlasUponRaiden = mkBaseBlock {
            name = "AtlasUponRaiden";
            user = "sam";
            identityFile = "~/.ssh/atlas_id_ed25519";
            identitiesOnly = true;
          };
          nix-atlasuponraiden = mkNixBlock { name = "AtlasUponRaiden"; };

          Naboo = mkBaseBlock {
            name = "Naboo";
            user = "sam";
            identityFile = "~/.ssh/naboo_id_ed25519";
            identitiesOnly = true;
          };
          nix-naboo = mkNixBlock { name = "Naboo"; };

          Nevarro = mkBaseBlock {
            name = "Nevarro";
            user = "sam";
            identityFile = "~/.ssh/nevarro_id_ed25519";
            identitiesOnly = true;
          };
          nix-nevarro = mkNixBlock { name = "Nevarro"; };

          EmeraldEcho = mkBaseBlock {
            name = "EmeraldEcho";
            user = "sam";
            identityFile = "~/.ssh/emeraldecho_id_ed25519";
            identitiesOnly = true;
          };
          nix-emeraldecho = mkNixBlock { name = "EmeraldEcho"; };

          GitHub =
            if builtins.elem hostname nixBlockHosts then
              {
                host = "github.com";
                hostname = "github.com";
                user = "git";
                identityFile = "~/.ssh/github_id_ed25519";
                identitiesOnly = true;
              }
            else
              null;

        });
      };
    };
}
