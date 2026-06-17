{
  inputs,
  ...
}:
let
  root = ../../../..;
in
{
  inherit root;
  primaryHostName = "EmeraldEcho";
  homeConfigurationName = "deck@EmeraldEcho";

  context = {
    primaryInteractiveUser = "sam";
    roles.steamdeck = true;
    deploy = {
      canDeployRemotely = false;
      sleepy = true;
    };
    ssh.enableNixBlocks = false;
    syncthing = {
      mode = "home";
      hasTray = false;
    };
  };

  users = {
    steam = {
      name = "sam";
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
      ];

      authorizedKeyPaths = [
        "atlasuponraiden/emeraldecho"
        "kamino/emeraldecho"
        "zaphodbeeblebrox/emeraldecho"
      ];
    };

    installer = {
      name = "jovian";
    };

    nixRemote = {
      authorizedKeyPaths = [
        "atlasuponraiden/emeraldecho_nix"
        "kamino/emeraldecho_nix"
        "zaphodbeeblebrox/emeraldecho_nix"
      ];
    };
  };

  systemPackages =
    pkgs: with pkgs; [
      deskflow
      noson
      rclone
      signal-desktop
      vlc
    ];

  homePackages =
    pkgs: with pkgs; [
      ferdium
      noson
      p7zip
      rclone
      signal-desktop
      vlc
    ];
}
