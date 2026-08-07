{ inputs }:
{ pkgs, ... }:
let
  reolinkCli = pkgs.callPackage ../../../tooling/reolink-cli/_package.nix { };
in
{
  networking.hostName = "Kamino";
  my.host = {
    name = "Kamino";
    formFactor = "laptop";
    home.enable = true;
    roles = {
      workstation = true;
      desktop = true;
      builder = true;
    };
    features = {
      gui = true;
      gdrive = true;
      atuin = true;
      personalMcp = true;
      vscode = true;
      firmware = true;
      nix-ld = true;
      docker = true;
      podman = true;
      bitwarden = true;
      deskflow = false;
      flatpak = true;
      minecraft = true;
      nvidia = true;
      noson = true;
      office = true;
      steam = true;
      threedprinter = true;
      wine = true;
      zsa = true;
    };
    services.ssh = true;
  };
  users.users.sam = {
    extraGroups = [
      "dialout"
      "networkmanager"
    ];
    openssh.authorizedKeys.keyFiles = [ "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/kamino.pub" ];
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "sam";
  };
  environment.systemPackages = [
    pkgs.czkawka
    reolinkCli
  ];
  my.unfreePackageNames = [ "reolink-cli" ];
  my.deployment = {
    enableRemoteUser = true;
    canDeployRemotely = true;
    sleepy = true;
    localFlakePath = "/home/sam/src/nix-dendrites";
  };
}
