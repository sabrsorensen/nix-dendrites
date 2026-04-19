{
  flake.modules.nixos.syncthing = {
    config = {
      # This is the basic syncthing module that only opens ports
      # For full configuration with devices/folders, use syncthing-server instead
      services.syncthing = {
        openDefaultPorts = true;
      };

      # Warning for users who might be looking for the full configuration
      warnings = [
        "Basic syncthing module only opens ports. For device/folder configuration, use syncthing-server module instead."
      ];
    };
  };
}
