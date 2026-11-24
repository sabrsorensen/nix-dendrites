{ inputs }:
{ pkgs, ... }:
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
      # System
      firmware = true;
      nvidia = true;
      bluetooth = true;
      bootGardener = true;
      nix-ld = true;
      smbMedia = true;

      # Containers
      docker = true;
      podman = true;

      # Desktop
      gui = true;
      plasma = true;
      deskflow = true;
      flatpak = true;

      # Shell and terminal
      ghostty = true;
      atuin = true;
      omnibin = true;

      # Development and AI
      zed = true;
      vscode = false;
      claude = true;
      personalMcp = true;

      # Personal apps and storage
      bitwarden = true;
      gdrive = true;
      office = true;

      # Peripherals and home devices
      zsa = true;
      threedprinter = true;
      reolink = true;
      sonos = true;

      # Gaming and Windows compatibility
      steam = true;
      wine = true;
      lutris = true;
      w3dHubLauncher = true;
      minecraft = true;
      noMansSky = true;
    };
    services.ssh = true;
  };
  users.users.sam = {
    extraGroups = [
      "dialout"
      "networkmanager"
    ];
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/kamino/zaphod.pub"
      "${inputs.nix-secrets}/ssh-keys/pabu/zaphod.pub"
    ];
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "sam";
  };
  environment.systemPackages = [
    pkgs.czkawka
  ];
  my.deployment = {
    enableRemoteUser = true;
    canDeployRemotely = true;
    sleepy = true;
    localFlakePath = "/home/sam/src/nix-dendrites";
  };
}
