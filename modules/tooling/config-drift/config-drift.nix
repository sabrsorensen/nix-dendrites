{ ... }:
let
  # `{ pkgs, ... }@args` (not a bare `args:`) is required: this repo's module
  # system only supplies config/lib/pkgs/etc. to a module function whose
  # declared pattern names at least one of them. A bare `args: ...` binding
  # gets called with an empty attrset and _config-drift.nix fails with
  # "called without required argument 'pkgs'" (see commit 503b343).
  homeModule = { pkgs, ... }@args: import ./_config-drift.nix args;
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.config-drift = homeModule;
}
