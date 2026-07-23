{ ... }:
{
  # Builders compile the Raspberry Pi closure locally through binfmt, matching
  # the predecessor's shared builder policy.
  flake.modules.nixos.cross-compile =
    { config, lib, ... }:
    lib.mkIf config.my.host.roles.builder {
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    };
}
