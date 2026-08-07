{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    inputs.terminal-rain-lightning.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
