args@{ ... }:
{
  programs.fish = (import ./_fish-base.nix args) // {
    functions = import ./_functions/_home.nix args;
  };
}
