{ lib, ... }:
{
  # Desktop-mode Steam autostart for EmeraldEcho, launched minimised to tray.
  # Replaces the copy Steam's own "Run Steam when my computer starts" setting
  # writes into ~/.config/autostart -- keep that setting off, or Steam will
  # fight the read-only Home Manager symlink.
  flake.modules.nixos.steam-autostart-emeraldecho =
    { config, ... }:
    lib.mkIf (config.my.host.name == "EmeraldEcho" && config.my.host.home.enable) {
      home-manager.users.${config.my.host.home.username} = import ./_steam-autostart.nix;
    };
}
