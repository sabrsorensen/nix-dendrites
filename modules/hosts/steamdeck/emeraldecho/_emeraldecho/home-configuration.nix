{
  inputs,
  shared,
}:
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    overlays = [ inputs.self.overlays.default ];
    config.allowUnfree = true;
  };
  extraSpecialArgs = {
    osConfig = shared.deckSteamOsConfig;
  };
  modules = [
    inputs.self.modules.homeManager.home
    inputs.self.modules.homeManager.sam-secrets
    inputs.self.modules.homeManager.EmeraldEcho
    (
      { pkgs, lib, ... }:
      {
        home.username = "deck";
        home.homeDirectory = "/home/deck";
        home.stateVersion = "26.05";
        home.packages = map (name: pkgs.${name}) shared.deckSteamHomePackages;
        home.activation.setupSteamLibraryMount = lib.hm.dag.entryAfter [
          "writeBoundary"
        ] shared.setupSteamLibraryMount;
      }
    )
  ];
}
