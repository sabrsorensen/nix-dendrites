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
            HostName = mkHostname name;
            Port = peer.ssh.base.port or 22;
            User = peer.ssh.base.user;
            IdentityFile = peer.ssh.base.identityFile;
          }
          // lib.optionalAttrs (peer.ssh.base.identitiesOnly or false) {
            IdentitiesOnly = true;
          };

      mkNixBlock =
        name: peer:
        if
          !(hostCfg.ssh.enableNixBlocks && peer ? ssh && peer.ssh ? nix && (peer.ssh.nix.enable or false))
        then
          null
        else
          {
            HostName = mkHostname name;
            Port = peer.ssh.nix.port or peer.ssh.base.port or 22;
            User = peer.ssh.nix.user or "nix-remote";
            IdentityFile = peer.ssh.nix.identityFile;
            IdentitiesOnly = true;
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
              AddKeysToAgent = "yes";
              ForwardAgent = true;
              Compression = true;
              ServerAliveInterval = 0;
              ServerAliveCountMax = 3;
              HashKnownHosts = false;
              UserKnownHostsFile = "~/.ssh/known_hosts";
            };

            GitHub =
              if hostCfg.ssh.enableNixBlocks then
                {
                  HostName = "github.com";
                  User = "git";
                  IdentityFile = "~/.ssh/github_id_ed25519";
                  IdentitiesOnly = true;
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
