{ inputs, lib, ... }:
{
  # Not `inputs.nixpkgs.follows = "nixpkgs"`: upstream's package recipe still
  # uses `nodePackages.asar`, which our newer nixpkgs has removed. Upstream's
  # own flake.nix tracks `nixpkgs-unstable` (a moving ref that also no longer
  # has it), so pin a dedicated nixpkgs at the exact rev upstream last locked
  # and tested against (same tactic as armory-runtime-nixpkgs).
  flake-file.inputs = {
    claude-desktop-nixpkgs.url = "github:NixOS/nixpkgs/6ad174a6dc07c7742fc64005265addf87ad08615";
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "claude-desktop-nixpkgs";
    };
  };

  # flake-file makes the input available after bootstrap; delay consumption so
  # this source module remains safe during flake generation.
  imports = lib.optional (inputs ? claude-desktop) ./_claude-desktop.nix;
}
