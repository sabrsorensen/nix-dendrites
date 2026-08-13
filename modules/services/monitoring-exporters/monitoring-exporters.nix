{ ... }:
{
  flake.modules.nixos.monitoring-exporters =
    { config, lib, ... }:
    {
      options.my.host.services.monitoringExporters =
        lib.mkEnableOption "Prometheus node and SMART exporter services";
      config = lib.mkIf config.my.host.services.monitoringExporters (
        import ./_monitoring-exporters.nix { }
      );
    };
}
