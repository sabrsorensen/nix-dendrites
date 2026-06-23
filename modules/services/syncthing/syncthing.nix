{
  flake.modules.nixos.syncthing =
    { config, lib, ... }:
    {
      config = lib.mkIf config.my.syncthing.enable {
        # This is the basic syncthing module that only opens ports.
        # For full configuration with devices/folders, use syncthing-server instead.
        services.syncthing.openDefaultPorts = true;

        warnings = [
          "Basic syncthing module only opens ports. For device/folder configuration, use syncthing-server module instead."
        ];
      };
    };
}
