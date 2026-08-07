{
  config,
  inputs,
  ...
}:
let
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
  payload = import ./_host.nix { inherit inputs network; };
in
{
  flake.nixosConfigurations.atlasuponraiden = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = builtins.attrValues config.flake.modules.nixos ++ [
      payload.hostModule
    ];
  };
}
