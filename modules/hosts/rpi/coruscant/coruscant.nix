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
    my.host = {
      address = rpi.network.coruscant;
      roles.rpi = true;
    };
    my.localDns.records = [
      { hostname = "homeassistant"; }
    ];

    # Disable problematic sysctl setting from nixos-raspberrypi
    boot.kernel.sysctl = lib.mkForce {
      # Remove vm.mmap_rnd_bits entirely - this kernel doesn't support it
    };
  };

  flake.lib.hostInventory.Coruscant = inputs.self.lib.mkInventoryHost {
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "switch";
    };
    outputs = inputs.self.lib.mkNixosOutputs {
      system = "aarch64-linux";
      name = "coruscant";
      configuration = "Coruscant";
    };
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Coruscant";
}
