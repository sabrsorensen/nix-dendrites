{ ... }:
{
  flake.modules.nixos.users-nixos-wsl =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (config.my.host.name == "NixOS-WSL") (import ./_content.nix args);
}
