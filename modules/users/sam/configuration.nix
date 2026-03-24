# user "system" configuration in flake.modules.nixos
#{
#  inputs,
#  self,
#  ...
#}:
#
#let
#in
{
#  flake.modules.nixos."${username}" =
#    {
#      pkgs,
#      ...
#    }:
#    {
#      imports = with inputs.self.modules.nixos; [
#      ];
#
#      users.users."${username}" = {
#        initialPassword = "changeme";
#        group = username;
#      };
#      programs.fish.enable = true;
#    };
}
