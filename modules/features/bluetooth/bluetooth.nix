{ ... }:
{
  flake.modules.nixos.bluetooth =
    { config, lib, ... }:
    {
      options.my.host.features.bluetooth = lib.mkEnableOption "Bluetooth";
      config = lib.mkIf config.my.host.features.bluetooth (
        import ./_bluetooth.nix { inherit config lib; }
      );
    };
}
