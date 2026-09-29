{ sonolin-src }:
{ pkgs, ... }:
{
  home.packages = [
    pkgs.noson
    (pkgs.callPackage ./_sonolin.nix { inherit sonolin-src; })
  ];

  warnings = [
    ''
      sonolin's postPatch adds a missing `import os` to tests/test_tags.py
      (upstream bug at 1429e886). Remove it from
      modules/features/sonos/_sonolin.nix once upstream fixes it -- the build
      fails with "drop this postPatch" when that happens, or check with:
        curl -s https://raw.githubusercontent.com/alexsson-xexpanderx/sonolin/main/tests/test_tags.py | grep -n '^import os'
    ''
  ];
}
