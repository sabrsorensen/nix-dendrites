{ inputs, ... }:
{
  flake.modules.nixos.determinate =
    { config, lib, ... }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      # The upstream module defaults to enabled, so explicitly connect its
      # daemon switch to the host feature.  The feature defaults to false.
      determinate.enable = config.my.host.features.determinateNix;

      warnings = lib.optional (!config.my.host.features.determinateNix) ''
        Determinate Nix is disabled pending verification of the SSH remote-store
        multiplexing fix: https://github.com/DeterminateSystems/nix-src/issues/441
        and https://github.com/DeterminateSystems/nix-src/pull/569
      '';
    };
}
