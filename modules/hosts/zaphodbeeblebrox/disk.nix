{ ... }:
{
  flake.modules.nixos.disk-zaphodbeeblebrox =
    { config, lib, ... }:
    lib.mkIf (config.my.host.name == "ZaphodBeeblebrox") (import ./_disk.nix);
}
