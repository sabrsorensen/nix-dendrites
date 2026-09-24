{ inputs, ... }:
let
  module =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isSteamDeck = config.my.host.platform == "steamdeck";
    in
    {
      # Jovian's option surface is imported on every host so broadcast
      # steamdeck modules can set `jovian.*` under their own gates. Almost all
      # of Jovian is behind its own enable options; the two exceptions are
      # neutralised here so non-Deck hosts get none of its behaviour:
      #   - modules/jovian/overlay.nix adds Jovian's package overlay
      #     (gamescope, mangohud, steam, ...) unconditionally, which silently
      #     replaced those packages -- and cache hits for everything built on
      #     them, e.g. Bottles -- on every desktop. Disabled and re-added only
      #     for the steamdeck platform.
      #   - modules/jovian/workarounds.nix defaults ignoreMissingKernelModules
      #     to true, making makeModulesClosure tolerate missing initrd kernel
      #     modules on every host. Default it on only for the Deck.
      imports = [ inputs.jovian-nixos.nixosModules.default ];
      disabledModules = [ "${inputs.jovian-nixos}/modules/jovian/overlay.nix" ];
      config = lib.mkMerge [
        { jovian.workarounds.ignoreMissingKernelModules = lib.mkDefault isSteamDeck; }
        (lib.mkIf isSteamDeck (
          lib.mkMerge [
            { nixpkgs.overlays = [ inputs.jovian-nixos.overlays.default ]; }
            (import ./_jovian.nix args)
          ]
        ))
      ];
    };
in
module
