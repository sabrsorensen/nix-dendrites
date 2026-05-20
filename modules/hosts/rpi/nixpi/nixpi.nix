{
  inputs,
  lib,
  ...
}:
let
  rpi = inputs.self.lib.rpi;
in
{
  flake.modules.nixos.NixPi = {
    imports = [
      (rpi.mkBaseModule "nixpi")
    ];

    networking = {
      hostName = "nixpi";
      useDHCP = true;
      interfaces.end0.useDHCP = true;
    };

    # Disable problematic sysctl setting from nixos-raspberrypi
    boot.kernel.sysctl = lib.mkForce {
      # Remove vm.mmap_rnd_bits entirely - this kernel doesn't support it
    };
  };
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "NixPi";
}
