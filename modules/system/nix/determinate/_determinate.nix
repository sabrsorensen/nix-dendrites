{ inputs, ... }:
{
  flake.modules.nixos.determinate =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      # Keep the daemon switch visible in host facts for the rare host that
      # needs to opt out of Determinate Nix.
      determinate.enable = config.my.host.features.determinateNix;
    };
}
