# Preservation investigation

## Decision

Do not migrate from impermanence yet. No current host enables
`my.host.features.impermanence`, and no current host is configured with an
ephemeral root filesystem. Revisit this investigation when selecting the first
such host; prefer introducing Preservation there directly rather than enabling
impermanence only to migrate it afterward.

## What Preservation provides

[Preservation](https://nix-community.github.io/preservation/) is declarative
NixOS management of non-volatile state. It is inspired by impermanence but is
not a drop-in replacement. Its `preservation.preserveAt` model makes several
state-lifetime details explicit:

- bind mounts versus symlinks (`how`);
- file and directory ownership, modes, and parent-directory setup;
- state needed during initrd (`inInitrd`), notably `/etc/machine-id`;
- system and per-user paths in one preservation root.

It implements this through systemd mount units and tmpfiles rather than an
interpreter-based persistence mechanism. It requires NixOS 24.11 or newer and
a systemd initrd. Atlas, Kamino, ZaphodBeeblebrox, EmeraldEcho, and NixPi
already evaluate with `boot.initrd.systemd.enable = true`.

## Fit with this repository

The current persistence policy is already separated by concern:

- `modules/features/impermanence/_content.nix` owns baseline system state;
- Bluetooth and Firefox add their own persistence payloads;
- `modules/home/persistence/_content.nix` owns shell and browser user state;
- `features.impermanence` aggregates the component feature defaults.

That separation is a good migration boundary. The public feature/broadcast
shape can remain; only its private persistence payloads need translation.
Preservation's explicit modes and early-boot behavior are especially useful
for SSH host keys, machine identity, and secrets-adjacent paths.

The existing `mkIfPersistence` helper and `environment.persistence` /
`home.persistence` payloads are impermanence-specific and must be translated,
not carried forward unchanged. Reassess `programs.fuse.userAllowOther` during
the migration: Preservation uses native systemd mounts, so the current FUSE
allowance may no longer be necessary.

## Migration plan for the first ephemeral-root host

1. Select one non-critical host with a separately mounted `/persistent` root
   and a recovery path.
2. Add Preservation as a delayed input/module provider; do not enable it on
   any other host.
3. Translate current baseline paths into `preservation.preserveAt."/persistent"`.
   Mark early state with `inInitrd = true` and specify permissions where they
   differ from the defaults.
4. Translate user state through Preservation's `users.<name>` paths. Ensure
   intermediate user directories receive appropriate ownership and modes.
5. Preserve SSH host keys with explicit ownership/mode review. Use symlinks
   only where early creation semantics require them.
6. Validate a cold boot, networking, secrets, Home Manager activation,
   rollback, and recovery before enabling persistence on a second host.

The upstream [migration guide](https://nix-community.github.io/preservation/impermanence-migration.html)
is a useful implementation checklist, particularly for key permissions,
initrd timing, symlink target creation, and intermediate directories. It does
not change this repository's decision to defer the migration until persistence
is actually activated.
