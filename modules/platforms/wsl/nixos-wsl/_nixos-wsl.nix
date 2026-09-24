{ lib, ... }:
{
  wsl = {
    enable = true;
    # Keep Windows .exe interop working if another module adds binfmt handlers.
    interop.register = true;
    startMenuLaunchers = true;
  };

  # WSL networking is NAT'd behind Windows; inbound SSH is never reachable, so
  # never open the Linux-side firewall for it regardless of what enables sshd.
  services.openssh.openFirewall = lib.mkForce false;
}
