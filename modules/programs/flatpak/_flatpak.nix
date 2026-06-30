{
  inputs,
  ...
}:
{
  flake.modules.nixos.flatpak =
    { config, lib, ... }:
    {
      imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

      config = lib.mkIf config.my.host.features.flatpak {
        services.flatpak = {
          enable = true;
          uninstallUnmanaged = true;
          packages = [
            "com.fastmail.Fastmail"
            "dev.krtirtho.Flemozi"
          ];
        };

        xdg.portal.enable = true;
      };
    };
}
