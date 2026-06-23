{
  inputs,
  ...
}:
{
  config,
  pkgs,
  ...
}:
let
  username = config.my.host.primaryInteractiveUser;
in
{
  imports = with inputs.self.modules.nixos; [
    wsl-base
  ];

  users.groups.${username} = { };
  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    group = username;
  };
}
