{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.my.features.claude || config.my.features.codex) {
    warnings = [
      ''
        ccusage: adding zstd to buildInputs because nixpkgs' cargo-setup-hook
        now exports ZSTD_SYS_USE_PKG_CONFIG=1 but the package doesn't list it.
        Remove the overrideAttrs in modules/home/ai-tools/_ai-tools.nix once
        this prints a match:
          grep -n zstd "$(nix eval --raw .#nixosConfigurations.kamino.pkgs.path)/pkgs/by-name/cc/ccusage/package.nix"
      ''
    ];

    home.packages = with pkgs; [
      (ccusage.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ zstd ];
      }))
      rtk
    ];
  };
}
