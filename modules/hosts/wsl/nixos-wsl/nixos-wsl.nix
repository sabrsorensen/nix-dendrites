{
  inputs,
  ...
}:
{
  flake.modules.nixos."NixOS-WSL" =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      username = config.my.wslUsername;
    in
    {
      imports = with inputs.self.modules.nixos; [
        wsl-base
        system-cli
      ];

      nixpkgs.config.allowUnfree = true;

      users.groups.${username} = { };
      users.users.${username} = {
        isNormalUser = true;
        home = "/home/${username}";
        extraGroups = [ "wheel" ];
        shell = pkgs.bash;
        group = username;
      };

      programs.fish.enable = true;

      home-manager.users.${username} = {
        imports = [
          inputs.self.modules.homeManager."NixOS-WSL"
        ];
        home.username = lib.mkDefault username;
        home.homeDirectory = lib.mkDefault "/home/${username}";
      };
    };

  flake.modules.homeManager."NixOS-WSL" = {
    imports = [ inputs.self.modules.homeManager."wsl-home" ];
  };

  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "NixOS-WSL";
}
