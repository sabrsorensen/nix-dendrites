{
  inputs,
  lib,
  ...
}:
let
  rpi = inputs.self.lib.rpi;
  static = rpi.mkStaticModule {
    hostName = "Coruscant";
    address = rpi.network.coruscant;
  };
in
{
  flake.modules.nixos.Coruscant = {
    imports = [
      (rpi.mkBaseModule "Coruscant")
    ]
    ++ static.imports;

    networking = static.networking;

    # Disable problematic sysctl setting from nixos-raspberrypi
    boot.kernel.sysctl = lib.mkForce {
      # Remove vm.mmap_rnd_bits entirely - this kernel doesn't support it
    };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Coruscant";
}
