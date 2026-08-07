{
  config,
  domain,
  lib,
  ...
}:
{
  console.keyMap = "dvorak";
  boot = {
    zfs.forceImportRoot = false;
    tmp = {
      useTmpfs = true;
      cleanOnBoot = true;
    };
  };
  nix.settings = {
    auto-optimise-store = true;
    builders-use-substitutes = true;
    cores = 0;
    download-buffer-size = 1024 * 1024 * 1024;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    keep-derivations = true;
    keep-outputs = true;
    max-jobs = "auto";
    warn-dirty = false;
    substituters = [
      "https://cache.nixos.org?priority=10"
      "https://install.determinate.systems"
      "https://nix-community.cachix.org"
      "https://attic.${domain}/atlas"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM"
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "atlas:YR+4cS0G0pzDX7vHi3Y3/vRBHiftc1WJC9R/g+tYeYA="
    ];
  };
  nix.extraOptions = lib.optionalString (config ? sops && config.sops.secrets ? github_nixos_token) ''
    !include ${config.sops.secrets.github_nixos_token.path}
  '';
  # Installed hosts retain their existing compatibility default. The
  # installation media module supplies its own state version.
  system.stateVersion = lib.mkIf (!builtins.elem "installer" config.my.host.tags) (
    lib.mkDefault "26.05"
  );
}
