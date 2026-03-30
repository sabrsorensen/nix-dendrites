# SDH-AnimationChanger Enhanced

`decky-animation-changer-enhanced` embeds `nix-animations.json` into the upstream `SDH-AnimationChanger` plugin and applies the Nix integration backend in `patches/decky-animation-changer-enhanced-main.py`.

## Supported Files

- `decky-animation-changer-enhanced.nix`
- `patches/decky-animation-changer-enhanced-main.py`

## Enhanced Package Usage

Use the enhanced package when you want to declaratively specify:

- the animation IDs that should be available locally
- which animation ID should override `boot`, `suspend`, or `throbber`
- the plugin `randomize` mode

Example:

```nix
{
  jovian.decky-loader.plugins = {
    "SDH-AnimationChanger" = pkgs.decky-animation-changer-enhanced.withAnimations {
      downloadAnimationIds = [ "YqL2Q" "PBRmG" "MnZgE" ];
      movieOverrides = [
        { movie = "boot"; animationId = "YqL2Q"; }
        { movie = "suspend"; animationId = "PBRmG"; }
        { movie = "throbber"; animationId = "PBRmG"; }
      ];
      randomize = "all";
    };
  };
}
```

## Configuration Inputs

`withAnimations` accepts:

- `downloadAnimationIds`
- `movieOverrides`
- `animationIds`
- `bootAnimation`
- `suspendAnimation`
- `throbberAnimation`
- `randomize`
- `forceIpv4`

For `movieOverrides`, `movie` may be one of:

- `boot`
- `suspend`
- `throbber`
- `deck_startup.webm`
- `steam_os_suspend.webm`
- `steam_os_suspend_from_throbber.webm`

## Notes

- The enhanced package downloads animation metadata and files at plugin runtime, not at Nix build time.
- `config.json` is expected to converge toward the same metadata-rich shape produced by normal store downloads once the plugin cache is available.
