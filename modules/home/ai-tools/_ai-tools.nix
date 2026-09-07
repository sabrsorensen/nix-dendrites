{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
in
{
  options.my.features.ai-tools = lib.mkEnableOption "AI Tools";
  config = lib.mkIf config.my.features.claude or config.my.features.codex {

    home.packages = with pkgs; [
      ccusage
      rtk
    ];
  };
}
