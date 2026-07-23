# nix-dendrites-broadcast

This is a clean Dendritic rewrite. `import-tree` imports every Nix file under
`modules/` whose path does not contain `/_`.

NixOS configuration files normally register modules under
`flake.modules.nixos`; flake tooling may instead register a flake-parts
contribution. Every host broadcasts the complete NixOS registry into its
evaluation. Those modules must therefore be safe everywhere and activate only
from `my.host` facts.

Hosts are deliberately direct declarations: their fact blocks show their roles,
features, and services without a descriptor builder or per-host feature-import
list. Files beginning with `_` are excluded from automatic discovery and are
used for private helpers or bootstrap-delayed input consumption, never module
aggregation.

Read [the architecture guide](docs/architecture.md) before adding a host,
feature, service, or flake input. It records the design rules and the reasons
behind them.

## Migration status

The system-level migration is substantially ported: host facts, hardware
edges, platforms, DNS/DHCP and reverse-proxy publication, the enabled service
stacks, Flatpak, secrets, Disko, Jovian, Home Manager (including the private
WSL work profile), and the declared NixOS outputs are in the broadcast-and-
gate structure. Remaining work is focused on runtime deployment validation.

See [the migration status](docs/migration-status.md) for the completed work,
validation performed, known gaps, and the recommended next-thread order.
