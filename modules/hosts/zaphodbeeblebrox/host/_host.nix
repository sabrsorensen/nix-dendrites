{ inputs }:
{ pkgs, ... }:
let
  reolinkCli = pkgs.callPackage ../../../tooling/reolink-cli/_package.nix { };
in
{
  networking.hostName = "ZaphodBeeblebrox";
  my.host = {
    name = "ZaphodBeeblebrox";
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
      claudeCode = true;
      firmware = true;
      nix-ld = true;
      bluetooth = true;
      docker = true;
      podman = true;
      bitwarden = true;
      deskflow = true;
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
    openssh.authorizedKeys.keyFiles = [ "${inputs.nix-secrets}/ssh-keys/kamino/zaphod.pub" ];
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
