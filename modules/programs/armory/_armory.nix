{
  inputs,
  lib,
  ...
}:
let
  supportedSystem = "x86_64-linux";

  mkArmoryPackage =
    pkgs:
    let
      runtimePkgs = inputs.armory-runtime-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      python = runtimePkgs.python27.withPackages (
        ps: with ps; [
          psutil
          pyqt4
        ]
      );
    in
    pkgs.stdenv.mkDerivation rec {
      pname = "armory";
      version = "0.96.5";

      src = pkgs.fetchurl {
        url = "https://github.com/goatpig/BitcoinArmory/releases/download/v${version}/armory_${version}_amd64_gcc7.2.deb";
        hash = "sha256-yDNH1oDVz2TkSBB3+EcEB0x9gpaBcDJRm5kGvExdBfo=";
      };

      nativeBuildInputs = [
        pkgs.autoPatchelfHook
        pkgs.dpkg
        pkgs.makeWrapper
        pkgs.replaceVars
      ];

      buildInputs = [
        pkgs.stdenv.cc.cc.lib
      ];

      dontUnpack = true;

      installPhase = ''
        runHook preInstall

        dpkg-deb -x "$src" "$out"

        mkdir -p "$out/bin" "$out/share/applications" "$out/share/pixmaps"
        ln -s "$out/usr/bin/ArmoryDB" "$out/bin/ArmoryDB"

        rm -f "$out/usr/bin/armory"
        cat > "$out/bin/armory" <<'EOF'
        #!@runtimeShell@
        export PATH="@runtimePath@:${PATH}"
        if [ -z "${HOME:-}" ] || [ "${HOME}" = "/homeless-shelter" ]; then
          HOME="$(@getent@ passwd "$(@id@ -un)" | @cut@ -d: -f6 || true)"
          if [ -z "${HOME:-}" ]; then
            HOME="/home/$(@id@ -un)"
          fi
          export HOME
        fi
        @mkdir@ -p "${HOME}/.bitcoin/blocks"
        cd "@armoryShareDir@"
        exec @python@ "@armoryQt@" "$@"
        EOF
        substituteInPlace "$out/bin/armory" \
          --replace-fail "@runtimeShell@" "${pkgs.runtimeShell}" \
          --replace-fail "@runtimePath@" "${lib.makeBinPath [
            pkgs.bitcoind
            pkgs.coreutils
            pkgs.glibc.bin
            pkgs.procps
            pkgs.util-linux
            pkgs.xdg-utils
          ]}:$out/bin:$out/usr/bin" \
          --replace-fail "@getent@" "${pkgs.glibc.bin}/bin/getent" \
          --replace-fail "@id@" "${pkgs.coreutils}/bin/id" \
          --replace-fail "@cut@" "${pkgs.coreutils}/bin/cut" \
          --replace-fail "@mkdir@" "${pkgs.coreutils}/bin/mkdir" \
          --replace-fail "@armoryShareDir@" "$out/usr/share/armory" \
          --replace-fail "@python@" "${python}/bin/python2" \
          --replace-fail "@armoryQt@" "$out/usr/lib/armory/ArmoryQt.py"
        chmod +x "$out/bin/armory"

        cat > "$out/share/applications/armory.desktop" <<EOF
        [Desktop Entry]
        Name=Armory
        Comment=Advanced Bitcoin Wallet Management Software
        Exec=armory
        Icon=armory
        Terminal=false
        Type=Application
        Categories=Office;Finance;
        EOF

        ln -s "$out/usr/share/armory/img/preferences256.png" "$out/share/pixmaps/armory.png"

        runHook postInstall
      '';

      meta = with lib; {
        description = "Advanced Bitcoin wallet management software";
        homepage = "https://github.com/goatpig/BitcoinArmory";
        license = with licenses; [
          agpl3Only
          mit
        ];
        mainProgram = "armory";
        platforms = [ supportedSystem ];
        sourceProvenance = [ sourceTypes.binaryNativeCode ];
      };
    };
in
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == supportedSystem) {
      packages.armory = mkArmoryPackage pkgs;
    };

  flake.modules.nixos.armory =
    { pkgs, ... }:
    {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.system == supportedSystem;
          message = "The Armory module is only supported on x86_64-linux because upstream only ships an amd64 Debian release and Armory depends on legacy PyQt4.";
        }
      ];

      environment.systemPackages =
        lib.optionals (pkgs.stdenv.hostPlatform.system == supportedSystem) [
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.armory
          pkgs.bitcoind
        ];
    };
}
