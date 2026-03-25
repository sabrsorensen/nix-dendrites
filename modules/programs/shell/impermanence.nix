{
  inputs,
  ...
}:
{
  flake.modules.homeManager.shell =
    {
      config,
      ...
    }:
    {
      home = inputs.self.lib.mkIfPersistence config {
        persistence."/persistent" = {
          directories = [ ".config/fish" ];
          files = [ ".bash_history" ];
        };
      };
    };
}
