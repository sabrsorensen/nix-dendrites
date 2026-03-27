{
  inputs,
  ...
}:
{
  flake.modules.nixos.NevarroImage = inputs.self.lib.rpi.mkImageModule "Nevarro";

  flake.nixosConfigurations = inputs.self.lib.mkNixos "aarch64-linux" "NevarroImage";
}
