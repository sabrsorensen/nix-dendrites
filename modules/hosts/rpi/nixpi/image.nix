{
  inputs,
  ...
}:
{
  flake.modules.nixos.NixPiImage = inputs.self.lib.rpi.mkImageModule "NixPi";

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "NixPiImage";
}
