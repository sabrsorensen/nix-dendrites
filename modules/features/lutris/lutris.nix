{ ... }:
{
  flake.modules.nixos.lutris =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      lutris = pkgs.lutris.override {
        buildFHSEnv =
          args:
          pkgs.buildFHSEnv (
            args
            // {
              multiPkgs = p: lib.filter (x: lib.getName x != "gtk+") (args.multiPkgs p);
            }
          );

        # Inside the FHS env so Lutris's "Enable MangoHud" system option
        # finds the wrapper and its (64- and 32-bit) Vulkan layer.
        extraPkgs = p: [ p.mangohud ];
      };
    in
    {
      options.my.host.features.lutris = lib.mkEnableOption "the Lutris game manager";

      config = lib.mkIf config.my.host.features.lutris {
        # nixpkgs ships the bubblewrap-FHS-wrapped Lutris, which carries its
        # own Wine / winetricks / DXVK runtime -- so this feature is
        # independent of my.host.features.wine. Games (e.g. Renegade X, via
        # Totem Arts' community installer) and their prefixes are downloaded
        # per-user into ~/Games at runtime; none of that state is managed here.

        # Lutris's FHS runtime references the (unfreeRedistributable) steam
        # package. Declared here so the feature stands on its own; harmless
        # where my.host.features.steam already allows the same names.
        my.unfreePackageNames = [
          "steam"
          "steam-unwrapped"
        ];

        # nixpkgs marks gtk2 (pname "gtk+") broken ahead of its removal
        # (NixOS/nixpkgs#410814), but pkgs/by-name/lu/lutris still lists it
        # in the FHS env's multiPkgs, so evaluating pkgs.lutris refuses.
        # Drop it from Lutris's FHS env rather than allowing the broken
        # package nixpkgs-wide: only native GTK2 Linux games need it, and
        # nothing run through Lutris here (Wine/Proton titles) is one.
        warnings = [
          ''
            lutris: filtering broken gtk2 ("gtk+") out of the lutris FHS env
            because nixpkgs' package still lists it
            (https://github.com/NixOS/nixpkgs/issues/410814).
            Remove the buildFHSEnv override in modules/features/lutris/lutris.nix
            once this prints nothing:
              grep -n gtk2 "$(nix eval --raw .#nixosConfigurations.kamino.pkgs.path)/pkgs/by-name/lu/lutris/package.nix"
          ''
        ];

        # Fixes a real Wine/Proton compatibility gap (unimplemented
        # powershell.exe stub breaking apps that use it for singleton-
        # instance detection, e.g. the Totem Arts Launcher used to install
        # Renegade X). Not gated on any particular game -- it's a one-shot
        # CLI tool run by hand against whichever prefix hits this, so it
        # costs nothing to have available whenever Lutris is.
        # See docs/lutris-renegade-x-launcher.md.
        environment.systemPackages = [
          lutris
          (pkgs.callPackage ./_powershell-stub.nix { })
        ];
      };
    };
}
