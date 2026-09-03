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

      options.my.host.features.determinateNix = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use Determinate Nix instead of the upstream Nix daemon.";
      };

      # Keep the daemon switch visible in host facts for the rare host that
      # needs to opt out of Determinate Nix.
      config.determinate.enable = config.my.host.features.determinateNix;

      # determinate.nixosModules.default sets nix.package to
      # inputs.determinate.inputs.nix.packages.<system>.default -- the actual
      # nix-src build (not inputs.determinate.packages.<system>.default,
      # which is just a thin wrapper around a pre-fetched determinate-nixd
      # binary with no nix-build/nix-store of its own; overriding nix.package
      # to that would leave the daemon's --nix-bin pointing at a directory
      # without a working Nix toolchain).
      #
      # This pin isn't served by Determinate's binary cache yet, so Atlas has
      # to build it from source. Its Nix API tests start nested Nix sandboxes
      # whose seccomp filter Atlas's kernel rejects (QEMU user-mode emulation,
      # used to cross-build aarch64-linux on Atlas, doesn't support nested
      # seccomp). Keep ordinary package builds sandboxed, but omit this
      # upstream self-test gate until the cache catches up.
      config.nix.package = lib.mkOverride 75 (
        inputs.determinate.inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (_: {
            doCheck = false;
          })
      );

      config.warnings = lib.optional config.my.host.features.determinateNix ''
        nix.package is overridden to skip nix-src's test suite (seccomp fails
        under Atlas's QEMU aarch64 emulation). The nix-src pin (PR #569, an
        SSH-socket fix) has merged, but Determinate's binary cache doesn't
        serve this exact rev yet, so it still builds from source. Remove this
        override once the cache catches up -- check with:
          nix build --impure --dry-run --expr \
            '(builtins.getFlake (toString ./.)).inputs.determinate.inputs.nix.packages.aarch64-linux.default'
        and confirm it reports substitutable paths rather than derivations to build.
      '';
    };
}
