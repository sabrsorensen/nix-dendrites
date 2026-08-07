{
  inputs,
  pkgs,
  ...
}:
{
  programs.herdr = {
    enable = true;
    package = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.herdr;
  };
}
