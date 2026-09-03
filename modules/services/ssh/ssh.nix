{ ... }:
{
  flake.modules.nixos.ssh =
    args@{ config, lib, ... }:
    {
      options.my.host.services.ssh = lib.mkEnableOption "OpenSSH server defaults";
      config = lib.mkIf (
        config.my.host.services.ssh
        || config.my.host.is.server
        || config.my.host.is.rpi
        || config.my.deployment.canDeployRemotely
        || config.my.deployment.enableRemoteUser
      ) (import ./_ssh.nix args);
    };
}
