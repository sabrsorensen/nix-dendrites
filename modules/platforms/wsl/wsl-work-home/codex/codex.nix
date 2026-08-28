{ inputs, ... }:
{
  # The codex-nix input is declared beside the base Codex feature in
  # modules/home/codex/codex.nix; this profile only consumes it.
  imports = [ (import ./_codex.nix { inherit inputs; }) ];
}
