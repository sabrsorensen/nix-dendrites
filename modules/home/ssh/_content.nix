{
  canDeployRemotely,
  config,
  domain,
  includeHostBlocks ? true,
  lib,
  username,
  ...
}:
let
  host = config.my.host;
  sshHosts = {
    atlasuponraiden = {
      alias = "AtlasUponRaiden";
      HostName = "AtlasUponRaiden.${domain}";
      User = "sam";
      IdentityFile = "~/.ssh/atlasuponraiden_id_ed25519";
    };
    kamino = {
      alias = "Kamino";
      HostName = "Kamino.${domain}";
      User = "sam";
      IdentityFile = "~/.ssh/kamino_id_ed25519";
    };
    zaphodbeeblebrox = {
      alias = "ZaphodBeeblebrox";
      HostName = "ZaphodBeeblebrox.${domain}";
      User = "sam";
      IdentityFile = "~/.ssh/zaphod_id_ed25519";
    };
    naboo = {
      alias = "Naboo";
      HostName = "Naboo.${domain}";
      User = "sam";
      IdentityFile = "~/.ssh/naboo_id_ed25519";
    };
    nevarro = {
      alias = "Nevarro";
      HostName = "Nevarro.${domain}";
      User = "sam";
      IdentityFile = "~/.ssh/nevarro_id_ed25519";
    };
    emeraldecho = {
      alias = "EmeraldEcho";
      HostName = "EmeraldEcho.${domain}";
      User = "sam";
      IdentityFile = "~/.ssh/emeraldecho_id_ed25519";
    };
  };
  sshHostBlocks = lib.mapAttrs' (
    _: peer:
    lib.nameValuePair peer.alias (
      builtins.removeAttrs peer [ "alias" ]
      // {
        Port = 22;
        IdentitiesOnly = true;
      }
    )
  ) (lib.filterAttrs (_: peer: peer.alias != host.name) sshHosts);
  nixSshHostBlocks =
    lib.mapAttrs'
      (
        name: host:
        lib.nameValuePair "nix-${name}" {
          inherit (host) HostName;
          Port = 22;
          User = "nix-remote";
          IdentityFile = "~/.ssh/nix_${name}_id_ed25519";
          IdentitiesOnly = true;
        }
      )
      (
        lib.filterAttrs (
          name: _:
          builtins.elem name [
            "atlasuponraiden"
            "emeraldecho"
            "kamino"
            "naboo"
            "nevarro"
            "zaphodbeeblebrox"
          ]
        ) sshHosts
      );
in
{
  home-manager.users.${username}.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ForwardAgent = true;
        Compression = true;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
      };
      GitHub = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/github_id_ed25519";
        IdentitiesOnly = true;
      };
    }
    // lib.optionalAttrs includeHostBlocks sshHostBlocks
    // lib.optionalAttrs canDeployRemotely nixSshHostBlocks;
  };
}
