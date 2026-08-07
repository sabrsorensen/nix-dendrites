{ ... }:
{
  nix.settings = {
    extra-substituters = [ "https://herdr.cachix.org" ];
    extra-trusted-public-keys = [
      "herdr.cachix.org-1:3nH7IStRsS0ASfdonA0DCRR2ZrSCeWitZ7Kwew0cR4I="
    ];
  };
}
