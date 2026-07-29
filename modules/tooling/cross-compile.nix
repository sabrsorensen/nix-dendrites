{ ... }:
{
  # Builders compile Raspberry Pi closures locally through binfmt.
  flake.modules.nixos.cross-compile =
    { config, lib, ... }:
    lib.mkIf config.my.host.roles.builder {
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };
}
