{
  flake.modules.nixos."cross-compile" = {
    boot = {
      binfmt = {
        # Enable aarch64-linux builds
        emulatedSystems = [ "aarch64-linux" ];
      };
    };
  };
}
