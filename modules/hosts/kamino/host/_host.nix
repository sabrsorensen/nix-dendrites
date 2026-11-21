{ inputs }:
{ pkgs, ... }:
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
      # System
      firmware = true;
      nvidia = false; # dGPU is failing; see hardware/_hardware.nix
      bootGardener = true;
      nix-ld = true;

      # Containers
      docker = true;
      podman = true;

      # Desktop
      gui = true;
      plasma = true;
      hyprland = true;
      niri = true;
      noctalia = true;
      deskflow = false;
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
      stm32 = true;

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
      lutris = false;
      w3dHubLauncher = false;
      minecraft = false;
      noMansSky = false;
    };
    services.ssh = true;
  };
  users.users.sam = {
    extraGroups = [
      "dialout"
      "networkmanager"
    ];
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/pabu/kamino.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/kamino.pub"
    ];
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "sam";
  };
  # Numlock on by default: the SDDM greeter, and the console (in case a boot
  # ever lands on a virtual terminal instead of the graphical session).
  services.displayManager.sddm.settings.General.Numlock = "on";
  systemd.services.numlockOnTty = {
    description = "Enable NumLock on console TTYs";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.kbd}/bin/setleds -D +num < /dev/tty1'";
    };
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
