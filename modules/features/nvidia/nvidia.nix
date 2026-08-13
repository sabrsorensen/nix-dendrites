{ ... }:
{
  flake.modules.nixos.nvidia =
    args@{ config, lib, ... }:
    {
      options.my.host.features.nvidia = lib.mkEnableOption "NVIDIA support";
      config = lib.mkIf config.my.host.features.nvidia (import ./_nvidia.nix args);
    };
}
