{ inputs, lib, ... }:
let
  # The my.features.claude option is declared here, always, so the
  # managed-user boundary (_home.nix) can set it before bootstrap; the
  # implementation is delayed until the inputs it consumes exist.
  homeModule =
    { lib, ... }:
    {
      options.my.features.claude = lib.mkEnableOption "Claude Code";
    };
  codeModule = import ./_claude-code.nix { inherit inputs; };
  homeModules = [
    homeModule
  ]
  ++ lib.optional (inputs ? claude-code && inputs ? claude-carbon) codeModule;
in
{
  flake-file.inputs = {
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:heytcass/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Packaged by _claude-carbon.nix; pinned to a release tag since the
    # wrapped script list there tracks upstream's scripts/ layout.
    claude-carbon = {
      url = "github:gwittebolle/claude-carbon/v1.8.0";
      flake = false;
    };
  };

  dendritic.homeManagerModules = homeModules;
  flake.modules.homeManager.claude.imports = homeModules;

  # `claude` is the aggregate: it defaults Claude Code on, and the Desktop app
  # on only for GUI hosts. Components gate on their own narrow flag so a host
  # can override one piece. Declared here -- always broadcast -- rather than
  # in the bootstrap-delayed desktop module, so the options exist even before
  # the claude-desktop input lands during flake generation.
  flake.modules.nixos.claude =
    { config, lib, ... }:
    let
      features = config.my.host.features;
    in
    {
      options.my.host.features = {
        claude = lib.mkEnableOption "Claude tooling (Code, plus the Desktop app on GUI hosts)";
        claudeCode = lib.mkEnableOption "Claude Code";
        claudeDesktop = lib.mkEnableOption "the Claude Desktop app";
      };

      config.my.host.features = lib.mkIf features.claude {
        claudeCode = lib.mkDefault true;
        claudeDesktop = lib.mkDefault features.gui;
      };
    };

  # flake-file makes the claude-desktop input available after bootstrap; delay
  # consumption so this source module remains safe during flake generation.
  imports = lib.optional (inputs ? claude-desktop) ./_claude-desktop.nix;
}
