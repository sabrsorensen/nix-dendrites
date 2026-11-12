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

        # nixpkgs marks gtk2 (pname "gtk+") broken ahead of its removal
        # (NixOS/nixpkgs#410814), but pkgs/by-name/lu/lutris still lists it
        # in the FHS env's multiPkgs, so evaluating pkgs.lutris refuses.
        # "ignore" rather than "warn" -- the warnings entry below already
        # carries the recheck command.
        nixpkgs.config.problems.handlers."gtk+".broken = "ignore";
        warnings = [
          ''
            lutris: allowing broken gtk2 ("gtk+") because nixpkgs' lutris FHS
            env still pulls it in (NixOS/nixpkgs#410814). Remove the
            problems.handlers override in modules/features/lutris/lutris.nix
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
          pkgs.lutris
          (pkgs.callPackage ./_powershell-stub.nix { })
        ];
      };
    };
}
