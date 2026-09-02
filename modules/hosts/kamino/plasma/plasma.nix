{ inputs, lib, ... }:
{
  # Kamino's Plasma deltas on top of the shared base in
  # modules/home/plasma/_plasma.nix. Gated on the host name and broadcast like
  # every other host-specific module (cf. hardware-zaphodbeeblebrox).
  flake.modules.nixos = lib.optionalAttrs (inputs ? plasma-manager) {
    plasma-kamino =
      { config, lib, ... }:
      lib.mkIf
        (config.my.host.name == "Kamino" && config.my.host.features.plasma && config.my.host.home.enable)
        {
          home-manager.users.${config.my.host.home.username}.programs.plasma = import ./_plasma.nix;
        };
  };
}
