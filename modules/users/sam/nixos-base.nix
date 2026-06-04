{
  lib,
  ...
}:
let
  username = "sam";
in
{
  flake.modules.nixos.sam-system-base = {
    users.users."${username}" = {
      description =
        lib.strings.toUpper (lib.strings.substring 0 1 username) + lib.strings.substring 1 (-1) username;
      group = username;
    };

    programs.fish.enable = true;
  };
}
