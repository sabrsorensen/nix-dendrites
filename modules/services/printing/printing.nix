{ ... }:
{
  flake.modules.nixos.printing =
    { config, lib, ... }:
    lib.mkIf (config.my.host.is.workstation && !config.my.host.is.steamdeck) (
      import ./_printing.nix { }
    );
}
