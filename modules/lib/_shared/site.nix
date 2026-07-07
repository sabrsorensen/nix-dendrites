{
  inputs,
  lib,
}:
let
  domain = lib.removeSuffix "\n" (builtins.readFile "${inputs.nix-secrets}/domain.txt");
  network = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/network.json");
in
{
  inherit domain network;
  atlas = {
    systemFeatures = [
      "benchmark"
      "big-parallel"
      "kvm"
      "nixos-test"
    ];
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "i686-linux"
    ];
    maxJobs = 4;
    speedFactor = 200;
  };
}
