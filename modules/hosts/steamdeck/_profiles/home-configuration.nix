{
  inputs,
  host,
}:
inputs.self.lib.mkHomeManager {
  system = "x86_64-linux";
  name = "deck@${host.primaryHostName}";
  username = "deck";
  homeDirectory = "/home/deck";
  stateVersion = "26.05";
  hostName = host.primaryHostName;
  hostContext = host.context;
  modules = [
    inputs.self.modules.homeManager.home
    inputs.self.modules.homeManager.sam-secrets
    inputs.self.modules.homeManager.${host.primaryHostName}
  ];
  extraConfig =
    {
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = host.homePackages pkgs;
      home.activation.setupSteamLibraryMount = lib.hm.dag.entryAfter [
        "writeBoundary"
      ] host.setupSteamLibraryMount;
    };
}
