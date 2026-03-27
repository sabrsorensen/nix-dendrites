bootMode:
{ ... }:
{
  imports = [
    ./steamdeck-steam.nix
    ./steamdeck-system.nix
    ../decky-loader/steamdeck-decky.nix
    (import ./steamdeck-hw-config.nix bootMode)
  ];
}
