{ ... }:
{
  flake.modules.nixos.services-atlasuponraiden =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "AtlasUponRaiden") (import ./_content.nix);
}
