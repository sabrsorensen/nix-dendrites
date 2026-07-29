default:
    @just --list --unsorted

main_audit := env_var_or_default("MAIN_AUDIT", "../nix-dendrites-main-audit")

# Show the state of the persistent, read-only predecessor reference checkout.
audit-reference:
    @git -C {{main_audit}} status --short
    @git -C {{main_audit}} log -1 --oneline

# Compare any repository-relative path with the predecessor without changing either checkout.
audit-diff path:
    @diff -ruN {{main_audit}}/{{path}} {{path}} || test $? -eq 1

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
