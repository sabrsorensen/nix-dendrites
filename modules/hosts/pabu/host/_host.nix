{ inputs }:
{ pkgs, ... }:
let
in
{
  networking.hostName = "Pabu";
  my.host = {
    name = "Pabu";
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
      claude = true;
      firmware = true;
      nix-ld = true;
      bluetooth = true;
      bitwarden = true;
      deskflow = true;
      flatpak = true;
      sonos = true;
      office = true;
      plasma = true;
      wine = true;
      impermanence = true;
      # /home is its own persistent subvolume, so Home Manager bind mounts
      # into /persist would be redundant.
      persistenceHome = false;
    };
    services.ssh = true;
  };
  users.users.sam = {
    extraGroups = [
      "dialout"
      "networkmanager"
    ];
    openssh.authorizedKeys.keyFiles = [
      #"${inputs.nix-secrets}/ssh-keys/kamino/pabu.pub"
      #"${inputs.nix-secrets}/ssh-keys/zaphod/pabu.pub"
    ];
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "sam";
  };
  environment.systemPackages = [
    pkgs.czkawka
  ];
  my.unfreePackageNames = [ ];
  my.deployment = {
    enableRemoteUser = true;
    canDeployRemotely = true;
    sleepy = true;
    localFlakePath = "/home/sam/src/nix-dendrites";
  };
}
