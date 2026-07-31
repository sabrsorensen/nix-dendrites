{
  config,
  inputs,
  pkgs,
  ...
}:
let
  username = config.my.host.home.username;
  herdrPackage = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home-manager.users.${username}.home.packages = [ herdrPackage ];
}
