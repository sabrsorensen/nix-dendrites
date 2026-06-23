{
  flake.modules.nixos.docker =
    { config, lib, ... }:
    {
      options.my.services.docker.enable = lib.mkEnableOption "Docker container runtime";

      config = lib.mkIf config.my.services.docker.enable {
        virtualisation.docker.enable = true;
      };
    };
}
