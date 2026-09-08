{ ... }:
{
  flake.modules.nixos.lutris =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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

        # Fixes a real Wine/Proton compatibility gap (unimplemented
        # powershell.exe stub breaking apps that use it for singleton-
        # instance detection, e.g. the Totem Arts Launcher used to install
        # Renegade X). Not gated on any particular game -- it's a one-shot
        # CLI tool run by hand against whichever prefix hits this, so it
        # costs nothing to have available whenever Lutris is.
        # See docs/lutris-renegade-x-launcher.md.
        environment.systemPackages = [
          pkgs.lutris
          (pkgs.callPackage ./_powershell-stub.nix { })
        ];
      };
    };
}
