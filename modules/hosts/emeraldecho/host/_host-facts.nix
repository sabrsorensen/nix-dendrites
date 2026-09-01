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
      atuin = true;
      decky = true;
      gui = true;
      deskflow = true;
      firmware = true;
      minecraft = true;
      noson = true;
    };
  };
  users.groups.sam.gid = 1000;
  users.users.sam = {
    uid = 1000;
    shell = hostPkgs.bash;
    openssh.authorizedKeys.keyFiles = [
      "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/emeraldecho.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino/emeraldecho.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/emeraldecho.pub"
    ];
  };
  my.deployment = {
    enableRemoteUser = true;
    localFlakePath = "/home/sam/src/nix-dendrites";
    authorizedKeyFiles = [
      "${inputs.nix-secrets}/ssh-keys/atlasuponraiden/emeraldecho_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/kamino/emeraldecho_nix.pub"
      "${inputs.nix-secrets}/ssh-keys/zaphodbeeblebrox/emeraldecho_nix.pub"
    ];
  };
  environment.systemPackages = with hostPkgs; [
    rclone
    signal-desktop
    vlc
  ];
}
