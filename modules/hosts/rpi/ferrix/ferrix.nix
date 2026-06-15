{
  inputs,
  lib,
  ...
}:
let
  rpi = inputs.self.lib.rpi;
  static = rpi.mkStaticModule {
    hostName = "Ferrix";
    address = rpi.network.ferrix;
  };
in
{
  flake.modules.nixos.Ferrix = {
    imports = [
      (rpi.mkBaseModule "Ferrix")
    ]
    ++ static.imports;

    networking = static.networking;
    my.host = {
      address = rpi.network.ferrix;
      roles.rpi = true;
    };

    # Disable problematic sysctl setting from nixos-raspberrypi
    boot.kernel.sysctl = lib.mkForce {
      # Remove vm.mmap_rnd_bits entirely - this kernel doesn't support it
    };
  };

  flake.lib.hostInventory.Ferrix = inputs.self.lib.mkInventoryHost {
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "switch";
    };
    outputs = inputs.self.lib.mkNixosOutputs {
      system = "aarch64-linux";
      name = "ferrix";
      configuration = "Ferrix";
    };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Ferrix";
}
