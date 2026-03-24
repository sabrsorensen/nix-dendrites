{
  inputs,
  ...
}:
{
  flake.modules.nixos.secrets =
    { pkgs, ... }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];
      environment.systemPackages = [
        pkgs.age
        pkgs.sops
        pkgs.ssh-to-age
      ];
    };

  flake.modules.homeManager.secrets =
    { pkgs, ... }:
    {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
      ];
    };

}
