{
  flake.modules.homeManager.starship =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.starship = {
        enable = true;
        enableBashIntegration = false;
        enableFishIntegration = true;
        enableIonIntegration = false;
        enableNushellIntegration = false;
        enableZshIntegration = false;
        enableInteractive = true;
        #enableTransience = true;
        # Configuration written to ~/.config/starship.toml
        settings = {
          add_newline = false;
          package.disabled = true;
          format = lib.concatStrings [
            "[┬─](bold purple)"
            "[\\[](dimmed blue)$username[@](bold bright-white)$hostname[:](bold bright-white)$directory[\\]](dimmed blue)"
            "[─](bold purple)"
            "$time"
            "[─](bold purple)"
            "$git_branch"
            "$git_commit"
            "$git_state"
            "$git_status"
            "$kubernetes"
            "$dotnet"
            "$golang"
            "$nodejs"
            "$python"
            "$rust"
            "$terraform"
            "$memory_usage"
            "$jobs"
            " $battery"
            "$line_break"
            "$cmd_duration"
            "[╰─⮞ ](bold purple)"
            "$character"
          ];

          username = {
            format = "[$user]($style)";
            show_always = true;
            style_user = "bold cyan";
          };

          hostname = {
            format = "[$ssh_symbol$hostname]($style)";
            ssh_symbol = "🌐";
            ssh_only = false;
            style = "bold blue";
          };

          battery = {
            charging_symbol = "󰂄";
            discharging_symbol = "💦";
            empty_symbol = "󰂎";
            format = "[$symbol$percentage]($style)";
            full_symbol = "󰁹";
            unknown_symbol = "󰂑";
          };

          battery.display = [
            {
              charging_symbol = "󰢞 ";
              discharging_symbol = "󰁹";
              style = "bold green";
              threshold = 100;
            }
            {
              charging_symbol = "󰢞 ";
              discharging_symbol = "󰂀";
              style = "bold orange";
              threshold = 70;
            }
            {
              charging_symbol = "󰢝 ";
              discharging_symbol = "󰁾";
              style = "bold yellow";
              threshold = 50;
            }
            {
              charging_symbol = "󰂆 ";
              discharging_symbol = "󰁻";
              style = "bold red";
              threshold = 25;
            }
          ];

          directory = {
            fish_style_pwd_dir_length = 1;
            format = "[$path/]($style)[$read_only]($read_only_style)";
            style = "bold green";
          };

          time = {
            disabled = false;
            format = "[\\[](dimmed blue)[$time]($style)[\\]](dimmed blue)";
            style = "bright-blue";
          };

          git_branch = {
            format = "[\\[](dimmed blue)[$symbol$branch]($style)[\\]](dimmed blue)";
            symbol = " ";
          };

          git_status = {
            disabled = false;
          };

          dotnet = {
            symbol = ".NET";
            disabled = false;
          };

          memory_usage = {
            disabled = false;
            format = "[\\[$symbol{$ram}(|{$swap})\\]]($style)";
            symbol = "🐏";
            threshold = -1;
          };

          cmd_duration = {
            format = "[├](bold purple) command took [$duration]($style)\n";
          };

          character = {
            success_symbol = "[\\$](bold green)";
            error_symbol = "[✗](bold red)";
          };

          nix_shell = {
            disabled = false;
          };
        };
      };
    };
}
