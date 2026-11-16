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
      # System
      firmware = true;
      bluetooth = true;
      impermanence = true;
      # /home is its own persistent subvolume, so Home Manager bind mounts
      # into /persist would be redundant.
      persistenceHome = false;
      nix-ld = true;

      # Desktop
      gui = true;
      plasma = true;
      deskflow = true;
      flatpak = true;

      # Shell and terminal
      ghostty = true;
      atuin = true;

      # Development and AI
      zed = true;
      vscode = true;
      claude = true;
      personalMcp = true;

      # Personal apps and storage
      bitwarden = true;
      gdrive = true;
      office = true;

      # Peripherals and home devices
      sonos = true;

      # Gaming and Windows compatibility
      wine = true;
    };
    services.ssh = true;
  };
  users.users.sam = {
    extraGroups = [
      "dialout"
      "networkmanager"
    ];
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/kamino/pabu.pub"
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
