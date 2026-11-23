{
  lib,
  stdenvNoCC,
  curl,
  cacert,
  gnugrep,
}:
# Fetches a Synergy package from symless.com without an account.
#
# Downloads need a short-lived token embedded in the package's download page,
# and that page only issues one to a browser holding the cookie set by
# Symless's anonymous download permalink (the same one the AUR synergy*-bin
# packages use). This is a fixed-output derivation, so the result is still
# pinned by `hash`; a broken permalink or page layout fails the fetch loudly
# instead of silently changing what gets installed.
{
  # Symless's product slug in the download URL, e.g. "synergy-personal-v3".
  product,
  # The package file name, e.g. "synergy-3.9.1-linux-resolute-x86_64.pkg.tar.zst".
  file,
  hash,
  # The OS slug in the download URL.
  os ? "arch-linux",
  permalink ? "https://email.mg.symless.com/c/eJxMjj1PwzAUAH-Ns1HZ7zn-GDw0gggJECBRqXSzXqw2JbEj2xTCr0d0Yry75QYHPgjTBCe0EdAqbXRzcgSDIkNGWC-EFzRwoFaRJm81tzo0owMOiisB3CJyvbHEEbHVEAhRKmSSz8dNWecplLKhNDeTO9W6FIZbBj2D_l-7Ugz5uDLo_TIy6If0Fafkhz9BFEph2Nf0ESLDW3l4PEO8ed6_bA_nRcLr2hHa9odqd6fu3_P-8-nte_fQiXbXZHcJMWWDRgKT3Gdf8xivQxcHvwEAAP__hk5M-A",
}:
stdenvNoCC.mkDerivation {
  name = file;

  nativeBuildInputs = [
    curl
    gnugrep
  ];

  SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  impureEnvVars = lib.fetchers.proxyImpureEnvVars;

  outputHashMode = "flat";
  outputHashAlgo = "sha256";
  outputHash = hash;

  preferLocalBuild = true;

  buildCommand = ''
    curl --fail --silent --show-error --location \
      --cookie-jar cookies.txt --output /dev/null \
      ${lib.escapeShellArg permalink}

    curl --fail --silent --show-error --location \
      --cookie cookies.txt --output page.html \
      ${lib.escapeShellArg "https://symless.com/synergy/download/package/${product}/${os}/${file}"}

    token=$(grep -oP '(?<=\\"token\\":\\")[^\\"]+' page.html | head -n1 || true)
    if [ -z "$token" ]; then
      echo "symless: no download token on the ${product} page for ${file};" >&2
      echo "the anonymous permalink or the page layout has probably changed." >&2
      exit 1
    fi

    curl --fail --silent --show-error --location --output "$out" \
      "https://symless.com/synergy/api/download/${file}?token=$token"
  '';
}
