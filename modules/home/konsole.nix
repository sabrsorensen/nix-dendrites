{ ... }:
{
  flake.modules.nixos.konsole =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = if config.my.host.platform == "wsl" then "ssorensen" else "sam";
    in
    lib.mkIf (config.my.host.features.gui && config.my.host.home.enable) {
      home-manager.users.${username} = import ./konsole/_content.nix { inherit pkgs; };
    };
}
