# Broadcast rewrite archive

These files are retained as historical evidence for the completed conversion
from the predecessor repository to the broadcast-and-gate architecture. They
are not current operating instructions and must not be used as a source of
module paths, host facts, or remaining work.

- `content-conversion-status.md` and `content-porting-workflow.md` describe the
  completed `_content.nix` normalization process.
- `main-file-manifest.txt` and `main-file-audit.tsv` map the predecessor tree
  to the rewrite as it existed during the conversion.
- `parity-audit.md` contains the detailed source-comparison evidence and its
  then-current validation notes.

The migration closed after successful Naboo/Nevarro peer-gated activations and
desktop deployments to Atlas and Emerald Echo. Deeper Steam Deck testing,
Atlas music-library exercise, and recovery-image boots are intentionally
non-blocking operational follow-up, not unfinished conversion work.

For current guidance, use `docs/architecture.md`; for planned persistence
work, use `docs/preservation-investigation.md`; and for the independent
database task, use `docs/postgresql-17-to-18-migration.md`.
