default:
    @just --list --unsorted

bootstrap-config host:
    @bash ./scripts/bootstrap-target.sh config {{host}}

bootstrap-output host:
    @bash ./scripts/bootstrap-target.sh output {{host}}

bootstrap-image-output host:
    @bash ./scripts/bootstrap-target.sh image-output {{host}}

bootstrap-final-config host:
    @bash ./scripts/bootstrap-target.sh final-config {{host}}

bootstrap-enroll target:
    bash ./scripts/bootstrap-enroll-remote.sh {{target}}

bootstrap-image host:
    nix build ".#$(bash ./scripts/bootstrap-target.sh image-output {{host}})"

install-anywhere host target:
    bash ./scripts/install-anywhere.sh {{host}} {{target}}

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

install-hooks:
    pre-commit install

run-hooks:
    pre-commit run --all-files

develop:
    nix develop
