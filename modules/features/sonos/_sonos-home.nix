{ sonolin-src }:
{ pkgs, ... }:
{
  home.packages = [
    pkgs.noson
    (pkgs.callPackage ./_sonolin.nix { inherit sonolin-src; })
  ];
}
