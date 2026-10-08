# Zed theme family (schema v0.2.0) built from Party Owl '84
# (github:sabrsorensen/partyowl84-vscode-theme, themes/Night Owl-color-theme.json):
# workbench colours mapped onto Zed's UI keys, TextMate token colours mapped onto
# Tree-sitter captures. Zed has no text-shadow, so the neon glow from
# src/js/theme_template.js can't be reproduced; its glow colours are used as
# the accents (rainbow brackets and indent guides) instead.
let
  bg = "#011627ff";
  muted = "#5f7e97ff";
  sidebar = "#001122ff";
  border = "#122d42ff";
  borderVariant = "#102a44ff";
  selection = "#1d3b53ff";
  purple = "#7e57c2";

  # Zed's status colour triple: foreground, 10% tint background, border.
  statusKeys = name: color: borderColor: {
    ${name} = "${color}ff";
    "${name}.background" = "${color}1a";
    "${name}.border" = borderColor;
  };
in
{
  "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
  name = "Party Owl '84";
  author = "sabrsorensen";
  themes = [
    {
      name = "Party Owl '84";
      appearance = "dark";
      style = {
        background = bg;
        border = border;
        "border.variant" = borderVariant;
        "border.focused" = "${purple}ff";
        "border.selected" = "#234d70ff";
        "border.transparent" = "#00000000";
        "border.disabled" = "#262a39ff";
        "elevated_surface.background" = "#021320ff";
        "surface.background" = sidebar;
        "element.background" = "#0b253aff";
        "element.hover" = "#234d708c";
        "element.active" = "#234d70ff";
        "element.selected" = "#234d708c";
        "element.disabled" = "#0b253aff";
        "drop_target.background" = "${purple}73";
        "ghost_element.background" = "#00000000";
        "ghost_element.hover" = "#234d708c";
        "ghost_element.active" = "#234d70ff";
        "ghost_element.selected" = "#234d708c";
        "ghost_element.disabled" = "#0b253aff";
        text = "#d6deebff";
        "text.muted" = "#8badc1ff";
        "text.placeholder" = muted;
        "text.disabled" = "#4b6479ff";
        "text.accent" = "#82aaffff";
        icon = "#d6deebff";
        "icon.muted" = muted;
        "icon.disabled" = "#4b6479ff";
        "icon.placeholder" = muted;
        "icon.accent" = "#82aaffff";
        "status_bar.background" = bg;
        "title_bar.background" = bg;
        "title_bar.inactive_background" = "#010e1aff";
        "toolbar.background" = bg;
        "tab_bar.background" = bg;
        "tab.inactive_background" = "#01111dff";
        "tab.active_background" = "#0b2942ff";
        "search.match_background" = "#1085bb5d";
        "search.active_match_background" = "#5f7e9779";
        "panel.background" = sidebar;
        "panel.focused_border" = "${purple}ff";
        "pane.focused_border" = null;
        "scrollbar.thumb.background" = "#084d8180";
        "scrollbar.thumb.hover_background" = "#084d81cc";
        "scrollbar.thumb.border" = "#00000000";
        "scrollbar.track.background" = "#00000000";
        "scrollbar.track.border" = "#00000000";
        "editor.foreground" = "#d6deebff";
        "editor.background" = bg;
        "editor.gutter.background" = bg;
        "editor.subheader.background" = sidebar;
        "editor.active_line.background" = "#00000033";
        "editor.highlighted_line.background" = "#0b2942ff";
        "editor.line_number" = "#4b6479ff";
        "editor.active_line_number" = "#c5e4fdff";
        "editor.hover_line_number" = "#8badc1ff";
        "editor.invisible" = "#5e81ce52";
        "editor.wrap_guide" = "#5e81ce26";
        "editor.active_wrap_guide" = "#5e81ce52";
        "editor.indent_guide" = "#5e81ce52";
        "editor.indent_guide_active" = "#7e97acff";
        "editor.document_highlight.read_background" = "#f6bbe533";
        "editor.document_highlight.write_background" = "#e2a2f433";
        "editor.document_highlight.bracket_background" = "#5f7e974d";
        "terminal.background" = bg;
        "terminal.foreground" = "#d6deebff";
        "terminal.bright_foreground" = "#ffffffff";
        "terminal.dim_foreground" = muted;
        "terminal.ansi.black" = "#011627ff";
        "terminal.ansi.bright_black" = "#575656ff";
        "terminal.ansi.dim_black" = "#010f1bff";
        "terminal.ansi.red" = "#ef5350ff";
        "terminal.ansi.bright_red" = "#ef5350ff";
        "terminal.ansi.dim_red" = "#a73a38ff";
        "terminal.ansi.green" = "#22da6eff";
        "terminal.ansi.bright_green" = "#22da6eff";
        "terminal.ansi.dim_green" = "#18994dff";
        "terminal.ansi.yellow" = "#c5e478ff";
        "terminal.ansi.bright_yellow" = "#ffeb95ff";
        "terminal.ansi.dim_yellow" = "#8aa054ff";
        "terminal.ansi.blue" = "#82aaffff";
        "terminal.ansi.bright_blue" = "#82aaffff";
        "terminal.ansi.dim_blue" = "#5b77b3ff";
        "terminal.ansi.magenta" = "#c792eaff";
        "terminal.ansi.bright_magenta" = "#c792eaff";
        "terminal.ansi.dim_magenta" = "#8b66a4ff";
        "terminal.ansi.cyan" = "#21c7a8ff";
        "terminal.ansi.bright_cyan" = "#7fdbcaff";
        "terminal.ansi.dim_cyan" = "#178b76ff";
        "terminal.ansi.white" = "#ffffffff";
        "terminal.ansi.bright_white" = "#ffffffff";
        "terminal.ansi.dim_white" = "#b3b3b3ff";
        "link_text.hover" = "#82aaffff";
        "version_control.added" = "#9ccc65ff";
        "version_control.modified" = "#e2b93dff";
        "version_control.deleted" = "#ef5350ff";
        "version_control.word_added" = "#99b76d40";
        "version_control.word_deleted" = "#ef535059";
        "version_control.conflict_marker.ours" = "#9ccc651a";
        "version_control.conflict_marker.theirs" = "#82aaff1a";
        accents = [
          "#7fdbcaff"
          "#c792eaff"
          "#82aaffff"
          "#57eaf1ff"
          "#f78c6cff"
          "#ff5874ff"
          "#c5e478ff"
          "#ffcb8bff"
        ];
        players = [
          {
            cursor = "#80a4c2ff";
            background = "#80a4c2ff";
            inherit selection;
          }
          {
            cursor = "#c792eaff";
            background = "#c792eaff";
            selection = "#c792ea3d";
          }
          {
            cursor = "#7fdbcaff";
            background = "#7fdbcaff";
            selection = "#7fdbca3d";
          }
          {
            cursor = "#f78c6cff";
            background = "#f78c6cff";
            selection = "#f78c6c3d";
          }
          {
            cursor = "#ff5874ff";
            background = "#ff5874ff";
            selection = "#ff58743d";
          }
          {
            cursor = "#c5e478ff";
            background = "#c5e478ff";
            selection = "#c5e4783d";
          }
        ];
        syntax = {
          attribute.color = "#c5e478ff";
          boolean.color = "#ff5874ff";
          comment = {
            color = "#637777ff";
            font_style = "italic";
          };
          "comment.doc" = {
            color = "#637777ff";
            font_style = "italic";
          };
          constant.color = "#82aaffff";
          constructor.color = "#57eaf1ff";
          "diff.minus".color = "#ef5350ff";
          "diff.plus".color = "#c5e478ff";
          embedded.color = "#d6deebff";
          emphasis = {
            color = "#c792eaff";
            font_style = "italic";
          };
          "emphasis.strong" = {
            color = "#c5e478ff";
            font_weight = 700;
          };
          enum.color = "#c5e478ff";
          function = {
            color = "#82aaffff";
            font_style = "italic";
          };
          hint = {
            color = "#5f7e97ff";
            font_style = "italic";
          };
          keyword = {
            color = "#c792eaff";
            font_style = "italic";
          };
          label.color = "#82aaffff";
          link_text.color = "#d6deebff";
          link_uri.color = "#ff869aff";
          namespace.color = "#b2ccd6ff";
          number.color = "#f78c6cff";
          operator.color = "#7fdbcaff";
          predictive = {
            color = "#5f7e97ff";
            font_style = "italic";
          };
          preproc.color = "#7fdbcaff";
          primary.color = "#d6deebff";
          property.color = "#baebe2ff";
          punctuation.color = "#d6deebff";
          "punctuation.bracket".color = "#d9f5ddff";
          "punctuation.delimiter".color = "#5f7e97ff";
          "punctuation.list_marker".color = "#ff5874ff";
          "punctuation.markup".color = "#82b1ffff";
          "punctuation.special".color = "#d3423eff";
          selector.color = "#ff6363ff";
          "selector.pseudo".color = "#c792eaff";
          string.color = "#21c7a8ff";
          "string.escape".color = "#f78c6cff";
          "string.regex".color = "#5ca7e4ff";
          "string.special".color = "#ecc48dff";
          "string.special.symbol".color = "#82aaffff";
          tag.color = "#caece6ff";
          "text.literal".color = "#80cbc4ff";
          title = {
            color = "#82b1ffff";
            font_weight = 700;
          };
          type.color = "#ffcb8bff";
          variable.color = "#d6deebff";
          "variable.parameter".color = "#7fdbcaff";
          "variable.special".color = "#7fdbcaff";
          variant.color = "#82aaffff";
        };
      }
      // statusKeys "conflict" "#ffeb95" "#5d5232ff"
      // statusKeys "created" "#9ccc65" "#38482fff"
      // statusKeys "deleted" "#ef5350" "#4c2b2cff"
      // statusKeys "error" "#ef5350" "#4c2b2cff"
      // statusKeys "hidden" "#5f7e97" border
      // statusKeys "hint" "#7fdbca" "#1d3b53ff"
      // statusKeys "ignored" "#395a75" border
      // statusKeys "info" "#64b5f6" "#1d3b53ff"
      // statusKeys "modified" "#e2b93d" "#5d4c2fff"
      // statusKeys "predictive" "#5f7e97" border
      // statusKeys "renamed" "#a2bffc" "#1d3b53ff"
      // statusKeys "success" "#22da6e" "#1f4a33ff"
      // statusKeys "unreachable" "#5f7e97" border
      // statusKeys "warning" "#ecc48d" "#5d4c2fff";
    }
  ];
}
