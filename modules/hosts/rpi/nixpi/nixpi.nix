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
    # This host intentionally stays DHCP-addressed, so my.host.address is left unset.
    my.host.roles.rpi = true;

    # Disable problematic sysctl setting from nixos-raspberrypi
    boot.kernel.sysctl = lib.mkForce {
      # Remove vm.mmap_rnd_bits entirely - this kernel doesn't support it
    };
  };

  flake.lib.hostInventory.NixPi = inputs.self.lib.mkInventoryHost {
    deploy = inputs.self.lib.mkInventoryDeploy {
      remoteMethod = "switch";
    };
    outputs =
      inputs.self.lib.mkNixosOutputs {
        system = "aarch64-linux";
        name = "nixpi";
        configuration = "NixPi";
      }
      ++ inputs.self.lib.mkNixosOutputs {
        system = "aarch64-linux";
        name = "nixpi-image";
        configuration = "NixPiImage";
        buildProduct = "sdImage";
      };
  };
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "NixPi";
}
