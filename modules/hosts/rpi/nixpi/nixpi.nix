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
  };
  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "NixPi";
}
