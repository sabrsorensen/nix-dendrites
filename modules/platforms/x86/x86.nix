{ ... }:
{
  flake.modules.nixos.platform-x86 =
    args@{ config, lib, ... }:
    lib.mkIf (config.my.host.platform != "rpi" && config.my.host.platform != "wsl") (
      import ./_content.nix args
    );
}
