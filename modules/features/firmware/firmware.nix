{ ... }:
{
  flake.modules.nixos.firmware =
    { config, lib, ... }:
    {
      options.my.host.features.firmware = lib.mkEnableOption "redistributable firmware";
      config = lib.mkIf config.my.host.features.firmware (import ./_firmware.nix { });
    };
}
