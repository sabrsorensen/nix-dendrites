default:
    @just --list --unsorted

write-flake:
    nix run .#write-flake

fmt:
    nix fmt

check:
    nix flake check

checknb:
    nix flake check --no-build

update:
    nix flake update

upwrite:
    nix flake update && nix run .#write-flake

install-hooks:
    pre-commit install

run-hooks:
    pre-commit run --all-files

develop:
    nix develop

config-drift:
    config-drift
