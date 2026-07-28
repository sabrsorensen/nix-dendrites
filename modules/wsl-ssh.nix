{ ... }:
{
  flake.modules.nixos.wsl-ssh =
    { config, lib, ... }:
    lib.mkIf (config.my.host.roles.wsl && config.my.host.home.enable) {
      home-manager.users.ssorensen.programs.ssh = {
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
        };
      };
    };
}
