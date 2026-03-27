{
  inputs,
  ...
}:
{
  flake.modules.nixos.NabooImage = inputs.self.lib.rpi.mkImageModule "Naboo";

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "NabooImage";
}
