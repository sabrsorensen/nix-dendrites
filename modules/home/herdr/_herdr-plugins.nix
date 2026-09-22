# Declarative Herdr plugins: each is a Nix derivation whose output root
# contains herdr-plugin.toml plus the built executable at the relative path
# its manifest's startup/action commands expect (e.g. `./herdr-auto-title`,
# `./target/release/herdr-spreader`) -- kevinpita/herdr-nix's `plugins.*.source`
# links this directory instead of running the manifest's own [[build]] step,
# so the plugin never needs a Go/Rust toolchain on Herdr's runtime PATH.
#
# `rev` is deliberately the moving branch name, not a commit/tag -- fetching
# is still a fixed-output derivation (network access is fine, sandboxed or
# not), but the *hash* stays pinned to whatever `main` last resolved to. When
# upstream moves `main` forward, the fetch's real content hash stops matching
# and the build fails loudly with the correct new hash in the error, instead
# of silently pulling in unreviewed plugin changes. To update: read what
# changed upstream, then paste the new hash the failure reports.
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
      hash = "sha256-7LL7Zxjet7zDlEdcoOfXeTyhRv51HkZRcs6Dgr/kJJY="; # main as of 2026-09-21
    };
    vendorHash = "sha256-QxFp1b7pf7bn3Hh0hyaj8ke5Z61N+WwjhHt3pFiapTs="; # also breaks loudly if go.sum drifts
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
