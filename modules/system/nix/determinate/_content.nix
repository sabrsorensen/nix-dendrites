{ inputs, ... }:
{
  flake.modules.nixos.determinate =
    { config, lib, ... }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      # Keep the daemon switch visible in host facts for the rare host that
      # needs to opt out of Determinate Nix.
      determinate.enable = config.my.host.features.determinateNix;

      warnings = lib.optional config.my.host.features.determinateNix ''
        Determinate Nix currently follows the temporary nix-src SSH fix in
        https://github.com/DeterminateSystems/nix-src/pull/569. Check that PR's
        merge status before returning determinate.inputs.nix to upstream main.
      '';
    };
}
