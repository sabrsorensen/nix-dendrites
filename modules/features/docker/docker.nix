{ ... }:
{
  flake.modules.nixos.docker =
    args@{ config, lib, ... }:
    {
      options.my.host.features.docker = lib.mkEnableOption "Docker container runtime";
      config = lib.mkIf config.my.host.features.docker (import ./_docker.nix args);
    };
}
