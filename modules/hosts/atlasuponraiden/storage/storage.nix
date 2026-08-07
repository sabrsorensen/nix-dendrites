{ ... }:
{
  flake.modules.nixos.storage-atlasuponraiden =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.name == "AtlasUponRaiden") (import ./_storage.nix args);
}
