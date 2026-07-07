{
  inputs,
  ...
}:
{
  root = ../../../..;
  hostName = "EmeraldEcho";

  config = {
    primaryInteractiveUser = "sam";
    formFactor = "handheld";
    roles.steamdeck = true;
    features = {
      deskflow = true;
      firmware = true;
      gui = true;
      noson = true;
    };
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
      bootstrap.initialPassword = "jovian";

      authorizedKeyPaths = [
        "atlasuponraiden/emeraldecho"
        "kamino/emeraldecho"
        "zaphodbeeblebrox/emeraldecho"
      ];
    };

    installer = {
      name = "jovian";
      description = "Steam Deck Installer User";
      password = "jovian";
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
      ];
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
      rclone
      signal-desktop
      vlc
    ];

  homePackages =
    pkgs: with pkgs; [
      ferdium
      p7zip
      rclone
      signal-desktop
      vlc
    ];
}
// import ./runtime.nix
// import ./variants.nix
