{ config, lib, ... }:
{
  # Installs niri, registers niri-session with the display manager, and sets
  # up its gnome/gtk portals, polkit agent support and gnome-keyring.
  # Enabling this feature defaults features.sddm on, which lists the session.
  programs.niri.enable = true;

  # nixpkgs' niri and plasma6 modules both mkDefault defaultSession, which
  # conflicts. Keep Plasma the default where it exists (pick niri at the
  # greeter); priority 900 still yields to a plain host-level choice.
  services.displayManager.defaultSession = lib.mkIf config.my.host.features.plasma (
    lib.mkOverride 900 "plasma"
  );

  # niri enables gnome-keyring, which mkDefault-enables its gcr SSH agent;
  # that asserts against programs.ssh.startAgent (modules/services/ssh).
  # Keep the repo-wide OpenSSH agent.
  services.gnome.gcr-ssh-agent.enable = lib.mkIf config.programs.ssh.startAgent false;
}
