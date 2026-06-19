{
  inputs,
  descriptor,
  host,
}:
# Home Manager only owns the SteamOS userland on this host. Anything wired in
# here should be treated as a user-session compatibility bridge, not as full OS
# ownership of the underlying SteamOS install.
inputs.self.lib.mkHomeManager {
  system = "x86_64-linux";
  name = descriptor.home.configurationName;
  username = "deck";
  homeDirectory = "/home/deck";
  stateVersion = "26.05";
  hostName = descriptor.hostName;
  hostContext = descriptor.config;
  modules = [
    inputs.self.modules.homeManager.home
    inputs.self.modules.homeManager.sam-secrets
    inputs.self.modules.homeManager.${descriptor.home.moduleName}
  ];
  extraConfig =
    {
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = host.homePackages pkgs;
      # SteamOS itself is outside this repo's control, so host-specific mount
      # reconciliation lives in Home Manager activation instead of a NixOS
      # module.
      home.activation.setupSteamLibraryMount = lib.hm.dag.entryAfter [
        "writeBoundary"
      ] host.setupSteamLibraryMount;
    };
}
