{ pkgs }:
# nixpkgs removed pnpm_9 (EOL 2026-04-30); several catalog plugins still ship
# a lockfileVersion 6.0/7.0 pnpm-lock.yaml that only pnpm 8/9 can read without
# a forced, drift-inducing regeneration. Rebuild the exact prior version
# (already permitted as an insecure package elsewhere in this module) from
# nixpkgs' own pnpm builder so those plugins keep using their real,
# upstream-committed lockfile verbatim.
pkgs.callPackage "${pkgs.path}/pkgs/development/tools/pnpm/generic.nix" {
  version = "9.15.9";
  hash = "sha256-z4anrXZEBjldQoam0J1zBxFyCsxtk+nc6ax6xNxKKKc=";
  # nixpkgs' own pnpm/default.nix passes this; without it callPackage supplies
  # pkgs.nodejs and generic.nix warns "Override nodejs-slim instead of nodejs".
  nodejs = null;
}
