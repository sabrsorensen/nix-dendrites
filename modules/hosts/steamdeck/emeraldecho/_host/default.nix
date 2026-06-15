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
      # bitwarden-desktop
      deskflow
      noson
      rclone
      signal-desktop
      vlc
    ];

  homePackages =
    pkgs: with pkgs; [
      # bitwarden-desktop
      ferdium
      noson
      p7zip
      rclone
      signal-desktop
      vlc
    ];
}
#
# The optional imports below are host escape hatches for SteamOS-specific
# compatibility work. Keep them separate from the inventory metadata above so it
# stays obvious which parts are declarative fleet state and which parts exist to
# bridge an unmanaged base OS.
# The simple host identity and package lists live above because they are small
# and stable. The remaining imports are the actual SteamOS/Jovian compatibility
# layers and variant definitions.
// import ./runtime.nix
// import ./variants.nix
