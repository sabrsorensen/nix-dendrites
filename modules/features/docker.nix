{ ... }:
{
  flake.modules.nixos.docker =
    { config, lib, ... }:
    lib.mkIf config.my.host.features.docker {
      virtualisation.docker.enable = true;
    };
}
