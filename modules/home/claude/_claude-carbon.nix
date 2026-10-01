{
  lib,
  stdenvNoCC,
  makeWrapper,
  jq,
  sqlite,
  gawk,
  bc,
  git,
  src,
}:
stdenvNoCC.mkDerivation {
  # Not in nixpkgs. Upstream is a plain bash Claude Code plugin (hooks,
  # /carbon-* skills, a status line) that expects jq and sqlite3 on PATH and
  # self-updates with git -- neither fits a store path, so wrap the entry
  # scripts with their tools and turn the update notifier off. The sourced
  # *-lib.sh files are left unwrapped. Bump by moving the claude-carbon
  # input's tag in claude.nix.
  pname = "claude-carbon";
  version = (lib.importJSON "${src}/.claude-plugin/plugin.json").version;
  inherit src;

  nativeBuildInputs = [
    makeWrapper
    jq
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    cp -r . "$out"
    chmod -R u+w "$out"

    # The manifest also offers the plugin's own full status line; drop it so
    # it can never compete with ccstatusline, which embeds --segment instead.
    jq 'del(.statusLine)' "$out/.claude-plugin/plugin.json" > plugin.json
    mv plugin.json "$out/.claude-plugin/plugin.json"

    for script in statusline persist-session persist-on-exit safety-rescan \
      backfill recompute generate-report generate-badge generate-pr-report; do
      # Some are only ever run as `bash script.sh`, so not marked executable.
      chmod +x "$out/scripts/$script.sh"
      wrapProgram "$out/scripts/$script.sh" \
        --prefix PATH : ${
          lib.makeBinPath [
            jq
            sqlite
            gawk
            bc
            git
          ]
        } \
        --set CLAUDE_CARBON_NO_UPDATE_NOTIFIER 1
    done

    runHook postInstall
  '';

  meta = {
    description = "Track the carbon footprint of Claude Code sessions";
    homepage = "https://github.com/gwittebolle/claude-carbon";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
