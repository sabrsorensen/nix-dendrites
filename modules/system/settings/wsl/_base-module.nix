{
  lib,
  pkgs,
  config,
  ...
}:
let
  username = config.my.host.primaryInteractiveUser or "sam";
in
{
  time.timeZone = lib.mkDefault "America/Boise";

  wsl = {
    enable = true;
    defaultUser = username;
    docker-desktop.enable = true;
    interop.register = true;
    startMenuLaunchers = true;
    wslConf.interop = {
      enabled = true;
      appendWindowsPath = true;
    };
  };

  users.users.${username}.extraGroups = [ "docker" ];
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
}
