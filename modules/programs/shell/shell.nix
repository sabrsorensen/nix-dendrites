{
  flake.modules.homeManager.shell =
    {
      config,
      ...
    }:
    {
      programs.bash = {
        enable = true;
        enableCompletion = true;
      };
    };

}
