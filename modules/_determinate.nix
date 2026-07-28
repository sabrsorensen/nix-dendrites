{ inputs, ... }:
{
  flake.modules.nixos.determinate =
    { config, ... }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      # The upstream module defaults to enabled, so explicitly connect its
      # daemon switch to the host feature.  The feature defaults to false.
      determinate.enable = config.my.host.features.determinateNix;
    };
}
