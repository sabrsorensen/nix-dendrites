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
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "Ferrix";
}
