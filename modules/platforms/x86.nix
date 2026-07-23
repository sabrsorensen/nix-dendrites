{ ... }:
{
  flake.modules.nixos.platform-x86 =
    { config, lib, ... }:
    lib.mkIf (!config.my.host.roles.rpi && !config.my.host.roles.wsl) {
      # Shared x86 policy belongs here. Host-specific boot, disks, and hardware
      # remain independent broadcast modules that gate on the same host facts.
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
