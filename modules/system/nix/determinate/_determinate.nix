{ inputs, ... }:
{
  flake.modules.nixos.determinate =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      options.my.host.features.determinateNix = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use Determinate Nix instead of the upstream Nix daemon.";
      };

      # Keep the daemon switch visible in host facts for the rare host that
      # needs to opt out of Determinate Nix.
      config.determinate.enable = config.my.host.features.determinateNix;
    };
}
