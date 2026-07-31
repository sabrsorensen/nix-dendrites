{
  lib,
  pkgs,
  username,
  ...
}:
{
  wsl = {
    defaultUser = username;
    docker-desktop.enable = true;
    startMenuLaunchers = true;
  };

  services.openssh.openFirewall = lib.mkForce false;
  programs.nix-ld.libraries = with pkgs; [
    icu
    openssl
    zlib
    stdenv.cc.cc.lib
  ];
  environment.systemPackages = with pkgs; [
    gnumake
    python3
    ripgrep
    sops
    ssh-to-age
    wget
  ];
  programs.fish.enable = true;
}
