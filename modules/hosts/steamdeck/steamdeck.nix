{
  inputs,
  lib,
  ...
}:
let
  steamdeck = import ./_public.nix { inherit inputs lib; };
  descriptors = [
    (
      let
        host = import ./emeraldecho/_host/default.nix { inherit inputs; };
      in
      {
        name = "EmeraldEcho";
        user.ssh = {
          identityFile = "~/.ssh/emeraldecho_id_ed25519";
          nixIdentityFile = "~/.ssh/nix_emeraldecho_id_ed25519";
        };
        home.outputName = "home-deck-emeraldecho";
        platform = {
          inherit host;
          registration = import ./emeraldecho/_host/registration.nix {
            inherit inputs lib host;
          };
        };
      }
    )
  ];
in
{
  imports = [ ./exports.nix ] ++ map steamdeck.mkRegisteredHost descriptors;

  flake-file.inputs = {
    jovian-nixos = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
