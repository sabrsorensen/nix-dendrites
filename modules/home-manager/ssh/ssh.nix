{
  flake.modules.homeManager.ssh =
    {
      config,
      inventory ? { },
      lib,
      osConfig ? { },
      ...
    }:
    let
      hostCfg = if osConfig ? my && osConfig.my ? host then osConfig.my.host else config.my.host;
      hostname = hostCfg.name;
      localDomain =
        if osConfig ? systemConstants && osConfig.systemConstants ? domain then
          osConfig.systemConstants.domain
        else
          hostCfg.domain;
      mkHostname =
        name: if localDomain != null && localDomain != "" then "${name}.${localDomain}" else name;
      mkBaseBlock =
        name: peer:
        if name == hostname || !(peer ? ssh && peer.ssh ? base) then
          null
        else
          {
            host = name;
            hostname = mkHostname name;
            port = peer.ssh.base.port or 22;
            user = peer.ssh.base.user;
            identityFile = peer.ssh.base.identityFile;
          }
          // lib.optionalAttrs (peer.ssh.base.identitiesOnly or false) {
            identitiesOnly = true;
          };

      mkNixBlock =
        name: peer:
        if
          !(hostCfg.ssh.enableNixBlocks && peer ? ssh && peer.ssh ? nix && (peer.ssh.nix.enable or false))
        then
          null
        else
          {
            host = "nix-${lib.toLower name}";
            hostname = mkHostname name;
            port = peer.ssh.nix.port or peer.ssh.base.port or 22;
            user = peer.ssh.nix.user or "nix-remote";
            identityFile = peer.ssh.nix.identityFile;
            identitiesOnly = true;
          };

      peerBlocks = lib.mapAttrs' (name: peer: lib.nameValuePair name (mkBaseBlock name peer)) inventory;
      nixBlocks = lib.mapAttrs' (
        name: peer: lib.nameValuePair "nix-${lib.toLower name}" (mkNixBlock name peer)
      ) inventory;

    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = lib.filterAttrs (_: v: v != null) (
          {
            "*" = {
              addKeysToAgent = "yes";
              forwardAgent = true;
              compression = true;
              serverAliveInterval = 0;
              serverAliveCountMax = 3;
              hashKnownHosts = false;
              userKnownHostsFile = "~/.ssh/known_hosts";
            };

            GitHub =
              if hostCfg.ssh.enableNixBlocks then
                {
                  host = "github.com";
                  hostname = "github.com";
                  user = "git";
                  identityFile = "~/.ssh/github_id_ed25519";
                  identitiesOnly = true;
                }
              else
                null;
          }
          // peerBlocks
          // nixBlocks
        );
      };
    };
}
