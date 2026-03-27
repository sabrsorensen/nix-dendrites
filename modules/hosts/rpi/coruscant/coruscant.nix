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
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Coruscant";
}
