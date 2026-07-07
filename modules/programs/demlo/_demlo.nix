{
  inputs,
  pkgs,
  ...
}:
{
  flake.modules.nixos.demlo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf config.my.services.media.enable {
      environment.systemPackages = [
        inputs.demlo.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
