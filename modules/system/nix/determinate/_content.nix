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

      # The temporary SSH-fix source is not served by Determinate's binary
      # cache, so Atlas has to build it. Its Nix API tests start nested Nix
      # sandboxes whose seccomp filter Atlas's kernel rejects. Keep ordinary
      # package builds sandboxed, but omit this upstream self-test gate until
      # the temporary source patch can be retired.
      nix.package = lib.mkOverride 75 (
        inputs.determinate-nix-src-ssh-fix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (_: {
            doCheck = false;
          })
      );

      warnings = lib.optional config.my.host.features.determinateNix ''
        Determinate Nix currently follows the temporary nix-src SSH fix in
        https://github.com/DeterminateSystems/nix-src/pull/569. Check that PR's
        merge status before returning determinate.inputs.nix to upstream main.
      '';
    };
}
