{
  inputs,
  lib,
  ...
}:
let
  site = import ./_site.nix { inherit inputs lib; };
  deployInventory = import ./_deploy-inventory.nix { inherit inputs lib; };
in
{
  flake.lib.shared =
    {
      hostContextOptions = import ./_host-context-options.nix { inherit lib; };
      mkSecretsSshKeyFiles =
        keyPaths: map (keyPath: "${inputs.nix-secrets}/ssh-keys/${keyPath}.pub") keyPaths;
      secretWrapArgsFromSpecs = import ./_secret-wrap-args.nix { inherit lib; };
      inherit site;
      syncthingCommonOptions = import ./_syncthing-common-options.nix;
      writeSourceReplacementScript = pkgs: import ./_write-source-replacement-script.nix { inherit pkgs; };
    }
    // deployInventory;
}
