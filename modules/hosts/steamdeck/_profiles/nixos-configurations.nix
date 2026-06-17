{
  inputs,
  lib,
  host,
}:
lib.mkMerge (map (variant: inputs.self.lib.mkNixos "x86_64-linux" variant.name) host.nixosVariants)
