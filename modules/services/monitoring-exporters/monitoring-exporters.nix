{ ... }:
{
  flake.modules.nixos.monitoring-exporters =
    { config, lib, ... }:
    lib.mkIf config.my.host.services.monitoringExporters (import ./_content.nix { });
}
