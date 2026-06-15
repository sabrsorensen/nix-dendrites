{
  inputs,
  pkgs,
  ...
}:
{
  flake.modules.nixos.demlo =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.demlo.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
