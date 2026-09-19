{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.my.features.claude || config.my.features.codex) {
    home.packages = with pkgs; [
      ccusage
      rtk
    ];
  };
}
