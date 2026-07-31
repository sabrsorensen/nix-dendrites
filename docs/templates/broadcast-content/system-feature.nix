# modules/features/example/example.nix
{ ... }:
{
  flake.modules.nixos.example =
    args@{
      config,
      lib,
      ...
    }:
    {
      config = lib.mkIf config.my.host.features.example (import ./_content.nix args);
    };
}

# modules/features/example/_content.nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.example ];
}
