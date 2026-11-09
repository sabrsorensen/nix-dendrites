# Declarative Herdr plugins: each is a Nix derivation whose output root
# contains herdr-plugin.toml plus the built executable at the relative path
# its manifest's startup/action commands expect (e.g. `./herdr-auto-title`,
# `./target/release/herdr-spreader`) -- kevinpita/herdr-nix's `plugins.*.source`
# links this directory instead of running the manifest's own [[build]] step,
# so the plugin never needs a Go/Rust toolchain on Herdr's runtime PATH.
#
# `rev` is deliberately the moving branch name, not a commit/tag -- fetching
# is still a fixed-output derivation (network access is fine, sandboxed or
# not), but the *hash* stays pinned to whatever `main` last resolved to. Once
# upstream moves `main` forward, a fresh fetch's real content hash stops
# matching and the build fails with the correct new hash in the error, instead
# of silently pulling in unreviewed plugin changes. A fixed-output derivation
# is only fetched when its path is missing, so a machine or builder still
# holding the old source keeps building it without noticing `main` moved.
# To update: read what changed upstream, then paste the new hash the failure
# reports. For autoTitle, also clear vendorHash and paste the hash that failure
# reports, whether or not go.sum changed.
{ pkgs }:
let
  spreaderSrc = pkgs.fetchFromGitHub {
    owner = "yuk1ty";
    repo = "herdr-spreader";
    rev = "main";
    hash = "sha256-nPuL1MUsMpgJYi0rPPBUdffp/SrI7T1fDkQBBVq/QZY="; # main as of 2026-09-21
  };
in
{
  autoTitle = pkgs.buildGoModule {
    pname = "herdr-auto-title";
    version = "unstable"; # tracks main; see rev note above
    src = pkgs.fetchFromGitHub {
      owner = "kryptamine";
      repo = "herdr-auto-title";
      rev = "main";
      hash = "sha256-Z9XWD7H6ityrKKvTlCY0eGV4oIAdgp34ghl982kCia4="; # main as of 2026-11-09 (e78dfca5)
    };
    vendorHash = "sha256-UfIpYaA2eIRl29fhi7ESEoHEsyiXmEZ4MO78T0Q6OCs="; # a stale value reuses the cached vendor tree; see the update note above
    subPackages = [ "cmd/herdr-auto-title" ];
    postInstall = ''
      cp $out/bin/herdr-auto-title $out/herdr-auto-title
      cp herdr-plugin.toml $out/
    '';
  };

  spreader = pkgs.rustPlatform.buildRustPackage {
    pname = "herdr-spreader";
    version = "unstable"; # tracks main; see rev note above
    src = spreaderSrc;
    cargoLock.lockFile = "${spreaderSrc}/Cargo.lock";
    postInstall = ''
      mkdir -p $out/target/release
      cp $out/bin/herdr-spreader $out/target/release/herdr-spreader
      cp herdr-plugin.toml $out/
    '';
  };
}
