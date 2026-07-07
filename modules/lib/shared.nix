{
  inputs,
  lib,
  ...
}:
let
  site = import ./_shared/site.nix { inherit inputs lib; };
  deploy = import ./_shared/deploy.nix { inherit inputs lib; };
  hostContextOptions = import ./_shared/host-context-options.nix { inherit lib; };
  mkSecretsSshKeyFiles =
    keyPaths: map (keyPath: "${inputs.nix-secrets}/ssh-keys/${keyPath}.pub") keyPaths;
  secretWrapArgsFromSpecs = import ./_shared/secret-wrap-args.nix { inherit lib; };
  syncthingCommonOptions = import ./_shared/syncthing-common-options.nix;
  writeSourceReplacementScript =
    pkgs: import ./_shared/write-source-replacement-script.nix { inherit pkgs; };
  hostContext = {
    options = hostContextOptions;
  };
  secrets = {
    inherit mkSecretsSshKeyFiles secretWrapArgsFromSpecs;
  };
  syncthing = {
    commonOptions = syncthingCommonOptions;
  };
  scripts = {
    inherit writeSourceReplacementScript;
  };
in
{
  flake.lib = {
    inherit
      deploy
      hostContext
      scripts
      secrets
      site
      syncthing
      ;
  }
  // deploy;
}
