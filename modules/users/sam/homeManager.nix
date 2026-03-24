# user home-manager configuration in flake.modules.homeManager
#{
#  inputs,
#  self,
#  ...
#}:
#
#let
#in
{
#  flake.modules.homeManager."${username}" = {
#    imports = with inputs.self.modules.homeManager; [
#      system-desktop
#    ];
#    home.packages = with pkgs; [
#      mediainfo
#    ];
#  };
}