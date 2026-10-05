# Claude Code custom theme (~/.claude/themes/<slug>.json, selected with
# `theme = "custom:<slug>"`) built from Party Owl '84
# (github:sabrsorensen/partyowl84-vscode-theme): the Night Owl editor palette
# plus the neon glow colours from its src/js/theme_template.js. Claude Code
# drops unknown keys and anything that isn't `#rrggbb`/`rgb(r,g,b)`, falling
# back to `base` for that key; the rainbow_* (ultrathink) keys and
# chromeYellow are left at the base's values on purpose.
{
  name = "Party Owl '84";
  base = "dark";
  overrides = {
    # Night Owl background/foreground and chrome.
    text = "#d6deeb";
    inverseText = "#011627";
    inactive = "#637777"; # comment colour
    inactiveShimmer = "#889a9a";
    subtle = "#4b6479"; # line numbers
    promptBorder = "#5f7e97";
    promptBorderShimmer = "#a2bffc";
    userMessageBackground = "#0b253a"; # input.background
    userMessageBackgroundHover = "#1d3b53"; # editor.selectionBackground
    composerSidebarBackground = "#001122"; # sideBar.background
    selectionBg = "#1d3b53";
    bashMessageBackgroundColor = "#1a1d2f"; # 10% #ff5874 over #011627
    memoryBackgroundColor = "#0e2a37"; # 10% #7fdbca over #011627

    # Claude's own accent stays orange: the neon orange token colour.
    claude = "#f78c6c";
    claudeShimmer = "#ffcb8b";
    clawd_body = "#f78c6c";
    clawd_background = "#011627";
    briefLabelClaude = "#f78c6c";
    briefLabelYou = "#82aaff";

    # Modes and prompts.
    autoAccept = "#c792ea";
    autoAcceptShimmer = "#e2c6f5";
    skill = "#c792ea";
    merged = "#c792ea";
    effortUltra = "#9982ff";
    planMode = "#21c7a8";
    bashBorder = "#ff5874";
    ide = "#57eaf1";
    claudeBlue_FOR_SYSTEM_SPINNER = "#82aaff";
    claudeBlueShimmer_FOR_SYSTEM_SPINNER = "#b0c9ff";
    permission = "#82aaff";
    permissionShimmer = "#b0c9ff";
    suggestion = "#82aaff";
    remember = "#82aaff";
    professionalBlue = "#82aaff";
    background = "#7fdbca";
    fastMode = "#f7652a";
    fastModeShimmer = "#f9a26c";
    rate_limit_fill = "#c792ea";
    rate_limit_empty = "#1d3b53";

    # Status.
    success = "#22da6e";
    error = "#ef5350";
    warning = "#ecc48d";
    warningShimmer = "#ffd68a";

    # Diff line/word backgrounds: terminal ANSI green #22da6e and red #ef5350
    # blended over #011627 at 35% (line), 15% (dimmed), 55% (word).
    diffAdded = "#0d5b40";
    diffRemoved = "#542b35";
    diffAddedDimmed = "#063332";
    diffRemovedDimmed = "#251f2d";
    diffAddedWord = "#13824e";
    diffRemovedWord = "#84373e";

    # Subagent colours from the terminal ANSI / token palette.
    red_FOR_SUBAGENTS_ONLY = "#ef5350";
    blue_FOR_SUBAGENTS_ONLY = "#82aaff";
    green_FOR_SUBAGENTS_ONLY = "#22da6e";
    yellow_FOR_SUBAGENTS_ONLY = "#ffeb95";
    purple_FOR_SUBAGENTS_ONLY = "#c792ea";
    orange_FOR_SUBAGENTS_ONLY = "#f78c6c";
    pink_FOR_SUBAGENTS_ONLY = "#ff5874";
    cyan_FOR_SUBAGENTS_ONLY = "#7fdbca";
  };
}
