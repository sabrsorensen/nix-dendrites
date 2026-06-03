{
  self,
  lib,
  ...
}:
let
  domain = lib.removeSuffix "\n" (builtins.readFile "${self.inputs.nix-secrets}/domain.txt");
  network = builtins.fromJSON (builtins.readFile "${self.inputs.nix-secrets}/network.json");
in
{
  flake.modules.generic.systemConstants =
    { lib, ... }:
    {
      options.systemConstants = lib.mkOption {
        type = lib.types.attrsOf lib.types.unspecified;
        default = { };
      };

      config.systemConstants = {
        inherit domain network;
        adminEmail = "admin@${domain}";
        atlas = {
          systemFeatures = [
            "benchmark"     # Can run benchmark builds
            "big-parallel"  # Has many cores for parallel builds
            "kvm"          # Has KVM virtualization support
            "nixos-test"   # Can run NixOS integration tests
          ];
          supportedSystems = [
            "x86_64-linux"   # Native architecture
            "aarch64-linux"  # Cross-compilation via emulation
            "i686-linux"     # 32-bit compatibility
          ];
          maxJobs = 16;
          speedFactor = 200; # Significantly prefer remote over local cross-compilation
        };
      };
    };
}
