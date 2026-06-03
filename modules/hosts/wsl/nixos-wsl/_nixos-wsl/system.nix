{
  inputs,
  ...
}:
{
  imports = with inputs.self.modules.nixos; [
    wsl-base
  ];
}
