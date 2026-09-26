{ ... }:
{
  flake.modules.nixos.disk-pabu =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "Pabu") (import ./_disk.nix);
}
