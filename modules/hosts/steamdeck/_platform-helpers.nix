{
  inputs,
  ...
}:
rec {
  mkDeckyModule =
    {
      steamUser ? "sam",
    }:
    import ./_platform/decky/steamdeck-decky.nix { inherit inputs steamUser; };
  mkHwConfig = bootMode: import ./_platform/steamdeck/steamdeck-hw-config.nix bootMode;
  mkSteamModule =
    {
      steamUser ? "sam",
    }:
    import ./_platform/steamdeck/steamdeck-steam.nix { inherit steamUser; };

  steamdeck = {
    inherit
      mkDeckyModule
      mkHwConfig
      mkSteamModule
      ;
  };
}
