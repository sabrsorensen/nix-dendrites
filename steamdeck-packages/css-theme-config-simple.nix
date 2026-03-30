{ writeTextFile }:

let
  buildNixCssThemeConfig =
    {
      themeDownloads ? [ ],
      themeStoreUrl ? "https://api.deckthemes.com",
      themes ? { },
    }:
    writeTextFile {
      name = "nix-css-themes.json";
      text = builtins.toJSON {
        theme_downloads = themeDownloads;
        theme_store_url = themeStoreUrl;
        inherit themes;
      };
    };
in
{
  inherit buildNixCssThemeConfig;
}
