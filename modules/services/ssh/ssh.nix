{ ... }:
{
  flake.modules.nixos.ssh =
    args@{ config, lib, ... }:
    lib.mkIf (
      config.my.host.services.ssh
      || config.my.host.is.server
      || config.my.host.is.rpi
      || config.my.deployment.canDeployRemotely
      || config.my.deployment.enableRemoteUser
    ) (import ./_content.nix args);
}
