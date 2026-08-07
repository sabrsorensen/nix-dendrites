{ inputs, ... }:
{
  flake.modules.nixos.users-sam =
    args@{
      config,
      lib,
      ...
    }:
    let
      enabled = config.my.host.home.enable && config.my.host.platform != "wsl";
    in
    lib.mkIf enabled (
      import ./_sam.nix (
        args
        // {
          inherit inputs;
        }
      )
    );
}
