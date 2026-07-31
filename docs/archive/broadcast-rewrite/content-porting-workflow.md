# Content-first module porting

The main branch is the behavioral source of truth while the broadcast rewrite
is being completed.  Module organization must not become a substitute for a
parity review.

## File roles

For each portable configuration payload:

- `module.nix` (or the existing public module file) owns flake registration,
  input declarations, broadcast/model binding, host/service selection, feature
  gates, and the adapter `let ... in` that translates model facts into payload
  parameters.
- `_content.nix` owns the portable NixOS or Home Manager payload. It should
  receive explicit parameters such as `cfg`, `username`, `domain`, `localAddr`,
  package selections, or feature booleans instead of reading the broadcast
  model directly.
- Files beginning with `_` are deliberately ignored by import-tree and are
  imported only by their public wrapper.

The public wrapper captures the complete Nix module argument set as `args`,
derives model-specific values in its adapter `let ... in`, and passes explicit
payload parameters to the content file:

```nix
# module.nix
{ inputs, ... }:
{
  flake-file.inputs.example.url = "github:owner/example";
  flake.modules.nixos.example =
    args@{ config, lib, ... }:
    let
      cfg = config.my.example;
      enabled = config.my.host.services.example;
      domain = builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile "${inputs.nix-secrets}/domain.txt"
      );
    in
    {
      options.my.example.enable = lib.mkEnableOption "Example service";
      config = lib.mkIf enabled (import ./_content.nix (args // { inherit cfg domain; }));
    };
}

# _content.nix
{ cfg, domain, pkgs, ... }:
{
  # effective NixOS or Home Manager payload
}
```

Treat the public module's `let ... in` block as the adapter layer from the
current module model into the parameters the payload needs. It reads
model-specific facts such as `config.my.host`, `config.my.deployment`, service
flags, and secrets inputs, then derives stable payload values such as `enabled`,
`username`, `cfg`, `domain`, `localAddr`, or package lists.

This keeps the payload reusable: a future module model should need to rewrite
or replace only the model adapter, not the content. If a module grows multiple
model adapters, add a small private adapter helper; do not push model-specific
fact reads into `_content.nix`.

## Porting procedure

1. Split the corresponding module on `main` first, without changing its
   evaluated settings.  Its new `_content.nix` is the canonical payload.
2. Compare that canonical payload with the rewrite's payload block by block.
3. Copy or adapt the main payload into the rewrite. Keep host/platform gates
   and model translation in the public wrapper/adapter; keep `_content.nix`
   parameterized.
4. If the rewrite intentionally differs, document the reason next to the
   wrapper or in the parity ledger before retaining the difference.  Do not
   silently preserve an alternative implementation.
5. Evaluate at least one host that enables the module; evaluate every affected
   host family when the setting is platform- or service-specific.
6. Mark the module complete in `docs/main-file-audit.tsv` only after the
   canonical content and its wrapper have both been reviewed.

## Review outcome

This structure makes duplicate configuration visible.  For example, Fish's
shared greeting belongs in the shared home payload; a WSL payload should
contain only WSL additions.  A second greeting is then a visible duplicate
rather than an interaction between two large mixed-purpose modules.
