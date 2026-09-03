{ inputs }:
{ pkgs, ... }:
let
  nurPkgs = pkgs.extend inputs.nur.overlays.default;
in
{
  packages.update-firefox-addons = pkgs.writeShellApplication {
    name = "update-firefox-addons";
    runtimeInputs = [ nurPkgs.nur.repos.rycee.mozilla-addons-to-nix ];
    text = ''
      repo_root="''${1:-$PWD}"
      input="$repo_root/modules/home/firefox/firefox-addons/firefox-addons.json"
      output="$repo_root/modules/home/firefox/firefox-addons/_firefox-addons.nix"

      if [ ! -f "$input" ] || [ ! -f "$repo_root/flake.nix" ]; then
        echo "usage: run from the repository root, or pass its path as the first argument" >&2
        exit 2
      fi

      mozilla-addons-to-nix "$input" "$output"
    '';
  };
}
