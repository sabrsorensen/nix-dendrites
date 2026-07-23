{ inputs, ... }:
{
  flake.modules.nixos.determinate =
    { ... }:
    {
      imports = [ inputs.determinate.nixosModules.default ];

      # Determinate owns the daemon on every NixOS output, including WSL. Keep
      # NixOS's Nix module enabled: Determinate redirects its generated
      # nix.conf to nix.custom.conf, which its daemon includes.
    };
}
