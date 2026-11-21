# modules/features/example/example.nix
{ ... }:
{
  flake.modules.nixos.example =
    args@{ config, lib, ... }:
    {
      options.my.host.features.example = lib.mkEnableOption "Example";
      config = lib.mkIf config.my.host.features.example (import ./_example.nix args);
    };
}

# modules/features/example/_example.nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.example ];
}
