{ lib, ... }:
{
  # Shared x86 policy; host-specific boot, disks, and hardware remain
  # separate broadcast modules gated by the same host facts.
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
