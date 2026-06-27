{ selectedTheme }:
{
  bakedThemeSettings =
    {
      "partyowl84" = {
        "partyowl84.brightness" = 1;
        "partyowl84.disableGlow" = false;
        "workbench.colorTheme" = "Party Owl '84";
        "workbench.preferredDarkColorTheme" = "Party Owl '84";
        "editor.tokenColorCustomizations" = {
          "[Party Owl '84]" = {
            "textMateRules" = [
              {
                "scope" = [
                  "entity.other.attribute-name.nix"
                  "meta.attribute-key.nix"
                  "variable.other.object.nix"
                  "variable.other.object.parameter.nix"
                  "variable.other.object.property.nix"
                  "variable.parameter.function.nix"
                  "variable.parameter.nix"
                ];
                "settings" = {
                  "foreground" = "#C5E478";
                  "fontStyle" = "italic";
                };
              }
              {
                "scope" = [
                  "variable.interpolation"
                  "variable.other.normal.shell.nix"
                ];
                "settings"."foreground" = "#ec5f67";
              }
              {
                "scope" = [
                  "variable.language.special"
                  "variable.language.special.shell.nix"
                  "variable.parameter.positional.shell.nix"
                ];
                "settings"."foreground" = "#8EACE3";
              }
            ];
          };
        };
      };
      "synthwave-blues" = {
        "synthwave84blues.brightness" = 1;
        "synthwave84blues.disableGlow" = false;
        "workbench.colorTheme" = "Synthwave Blues";
        "workbench.preferredDarkColorTheme" = "Synthwave Blues";
        "editor.tokenColorCustomizations" = {
          "[Synthwave Blues]" = {
            "textMateRules" = [
              {
                "scope" = [
                  "entity.other.attribute-name.nix"
                  "meta.attribute-key.nix"
                  "variable.other.object.nix"
                  "variable.other.object.parameter.nix"
                  "variable.other.object.property.nix"
                  "variable.parameter.function.nix"
                  "variable.parameter.nix"
                ];
                "settings" = {
                  "foreground" = "#C5E478";
                  "fontStyle" = "italic";
                };
              }
              {
                "scope" = [
                  "variable.interpolation"
                  "variable.other.normal.shell.nix"
                ];
                "settings"."foreground" = "#ec5f67";
              }
              {
                "scope" = [
                  "variable.language.special"
                  "variable.language.special.shell.nix"
                  "variable.parameter.positional.shell.nix"
                ];
                "settings"."foreground" = "#8EACE3";
              }
            ];
          };
        };
      };
      "synthwave-84" = {
        "synthwave84.brightness" = 1;
        "synthwave84.disableGlow" = false;
        "workbench.colorTheme" = "SynthWave 84";
        "workbench.preferredDarkColorTheme" = "SynthWave 84";
        "editor.tokenColorCustomizations" = {
          "[SynthWave 84]" = {
            "textMateRules" = [
              {
                "scope" = [
                  "entity.other.attribute-name.nix"
                  "meta.attribute-key.nix"
                  "variable.other.object.nix"
                  "variable.other.object.parameter.nix"
                  "variable.other.object.property.nix"
                  "variable.parameter.function.nix"
                  "variable.parameter.nix"
                ];
                "settings" = {
                  "foreground" = "#C5E478";
                  "fontStyle" = "italic";
                };
              }
              {
                "scope" = [
                  "variable.interpolation"
                  "variable.other.normal.shell.nix"
                ];
                "settings"."foreground" = "#ec5f67";
              }
              {
                "scope" = [
                  "variable.language.special"
                  "variable.language.special.shell.nix"
                  "variable.parameter.positional.shell.nix"
                ];
                "settings"."foreground" = "#8EACE3";
              }
            ];
          };
        };
      };
    }
    .${selectedTheme} or { };
}
