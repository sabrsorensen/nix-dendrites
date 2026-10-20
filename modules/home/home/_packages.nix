# Base managed-user packages, shared by the NixOS managed-user boundary
# (_home.nix) and standalone Home Manager configs (e.g. emeraldecho-steamos).
{
  inputs,
  lib,
  pkgs,
  gui,
}:
with pkgs;
[
  cowsay
  fortune
  jq
  lolcat
  mediainfo
  nerd-fonts.caskaydia-cove
  (runCommandLocal "gitignore" { } ''
    install -Dm755 ${inputs.gitignore}/gitignore "$out/bin/gitignore"
  '')
]
++ lib.optionals gui [
  clementine
  discord
  ferdium
  plex-desktop
  qdirstat
  signal-desktop
  vlc
]
