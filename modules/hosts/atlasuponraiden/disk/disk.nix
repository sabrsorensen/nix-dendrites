{ ... }:
{
  flake.modules.nixos.disk-atlasuponraiden =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "AtlasUponRaiden") (import ./_content.nix);
}
