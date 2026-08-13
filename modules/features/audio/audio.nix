{ ... }:
{
  flake.modules.nixos.audio =
    { config, lib, ... }:
    {
      options.my.host.features.audio = lib.mkEnableOption "local audio stack";
      config = lib.mkIf config.my.host.features.audio (import ./_audio.nix { });
    };
}
