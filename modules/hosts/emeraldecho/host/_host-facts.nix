{
  hostPkgs,
  inputs,
}:
{
  networking.hostName = "EmeraldEcho";

  my.host = {
    name = "EmeraldEcho";
    formFactor = "handheld";
    platform = "steamdeck";
    home.enable = true;
    roles.workstation = true;
    features = {
      # System
      firmware = true;
      bootGardener = true;

      # Desktop
      gui = true;
      plasma = true;
      deskflow = true;
      firefox = true;

      # Shell and terminal
      atuin = true;

      # Development and AI
      zed = true;

      # Personal apps and storage
      bitwarden = true;

      # Peripherals and home devices
      sonos = true;

      # Gaming and Windows compatibility
      decky = true;
      wine = true;
      lutris = true;
      w3dHubLauncher = true;
      minecraft = true;
      noMansSky = true;
    };
  };
  users.groups.sam.gid = 1000;
  users.users.sam = {
    uid = 1000;
    shell = hostPkgs.bash;
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/emeraldecho.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino/emeraldecho.pub"
      "${inputs.nix-secrets}/ssh-keys/pabu/emeraldecho.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/emeraldecho.pub"
    ];
  };
  my.deployment = {
    enableRemoteUser = true;
    localFlakePath = "/home/sam/src/nix-dendrites";
    authorizedKeyFiles = [
      "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/emeraldecho_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino/emeraldecho_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/pabu/emeraldecho_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/emeraldecho_nix.pub"
    ];
  };
  environment.systemPackages = with hostPkgs; [
    kdePackages.kdialog
    rclone
    signal-desktop
    vlc
  ];
}
