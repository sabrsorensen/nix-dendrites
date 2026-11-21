{ ... }:
let
  homeModule = import ./_noctalia-home.nix;
  featureModule =
    args@{ config, lib, ... }:
    {
      options.my.features.noctalia = lib.mkEnableOption "Noctalia shell configuration";
      config = lib.mkIf config.my.features.noctalia (homeModule args);
    };
in
{
  dendritic.homeManagerModules = [ featureModule ];
  flake.modules.homeManager.noctalia = featureModule;

  flake.modules.nixos.noctalia =
    args@{ config, lib, ... }:
    {
      options.my.host.features.noctalia =
        lib.mkEnableOption "the Noctalia Wayland shell (bar, launcher, notifications)";
      config = lib.mkIf (config.my.host.features.noctalia && config.my.host.home.enable) (
        import ./_noctalia-nixos.nix args
      );
    };
}
