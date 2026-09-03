{ inputs, lib, ... }:
let
  homeModule = import ./_claude-code.nix { inherit inputs; };
in
{
  flake-file.inputs = {
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };

    # Not `inputs.nixpkgs.follows = "nixpkgs"`: upstream's package recipe still
    # uses `nodePackages.asar`, which our newer nixpkgs has removed. Upstream's
    # own flake.nix tracks `nixpkgs-unstable` (a moving ref that also no longer
    # has it), so pin a dedicated nixpkgs at the exact rev upstream last locked
    # and tested against (same tactic as armory-runtime-nixpkgs).
    claude-desktop-nixpkgs.url = "github:NixOS/nixpkgs/6ad174a6dc07c7742fc64005265addf87ad08615";
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "claude-desktop-nixpkgs";
    };
  };

  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.claude = homeModule;

  # Single gate for all Claude tooling: Claude Code (Home Manager, via
  # _claude-code.nix) and the Claude Desktop app (NixOS, via
  # _claude-desktop.nix). Declared here -- always broadcast -- rather than in
  # the bootstrap-delayed desktop module, so the option exists even before the
  # claude-desktop input lands during flake generation.
  flake.modules.nixos.claude =
    { lib, ... }:
    {
      options.my.host.features.claude =
        lib.mkEnableOption "Claude tooling (Code, Desktop app, usage monitor)";
    };

  # flake-file makes the claude-desktop input available after bootstrap; delay
  # consumption so this source module remains safe during flake generation.
  imports = lib.optional (inputs ? claude-desktop) ./_claude-desktop.nix;
}
