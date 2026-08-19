{
  description = "Warp Terminal (preview) packaged from .deb on NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    debUrls = {
      x86_64-linux = "https://app.warp.dev/download?channel=preview&package=deb";
      aarch64-linux = "https://app.warp.dev/download?channel=preview&package=deb_arm64";
    };
    debShas = {
      x86_64-linux = "sha256-ffgu4MMc3Ej9FNPK+63iRDFo5q0Gwf3vQYBrF7VHMqE=";
      aarch64-linux = "sha256-nDghQoZMkEsTOtbuMoZREY2wlMxdbn58MUn0f2o/kIc=";
    };
    forAll = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    }));
  in {
    packages = forAll (pkgs:
      let system = pkgs.stdenv.hostPlatform.system;
      in {
        default = pkgs.stdenv.mkDerivation {
          pname   = "warp-terminal-preview";
          version = "0.2026.08.18.02.52.preview.00";

          src = pkgs.fetchurl {
            url = debUrls.${system};
            sha256 = debShas.${system};
            curlOptsList = [ "-L" ];
            name = "warp-preview-${system}.deb";
          };

          nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.dpkg pkgs.makeWrapper pkgs.file ];
          buildInputs = with pkgs; [
            stdenv.cc.cc zlib libGL curl alsa-lib
            libx11 libxext libxcursor libxi libxrandr libxcb
            libxkbcommon wayland gtk3 pango cairo fontconfig freetype libdrm
          ];

          unpackPhase = ''dpkg-deb -x $src .'';

          installPhase = ''
            mkdir -p $out/bin $out/share
            cp -r usr/share/* $out/share/
            cp -r opt/warpdotdev/warp-terminal-preview $out/libexec

            makeWrapper $out/libexec/warp-preview $out/bin/warp \
              --prefix PATH : /run/wrappers/bin \
              --prefix XDG_DATA_DIRS : "$out/share" \
              --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
                pkgs.libGL pkgs.libxkbcommon pkgs.wayland pkgs.libx11
                pkgs.libxcursor pkgs.libxi pkgs.libxrandr
                pkgs.fontconfig pkgs.freetype
              ]}

            if [ -d "$out/share/applications" ]; then
              for d in "$out/share/applications/"*.desktop; do
                [ -f "$d" ] || continue
                sed -i "s|^Exec=.*|Exec=$out/bin/warp|" "$d" || true
              done
            fi
          '';

          meta = with pkgs.lib; {
            description = "Warp Terminal (preview) packaged from vendor .deb";
            platforms   = platforms.linux;
            license     = licenses.unfree;
          };
        };
      }
    );

    apps = nixpkgs.lib.genAttrs systems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/warp";
        meta.description = "Run Warp Terminal preview";
      };
    });

    checks = nixpkgs.lib.genAttrs systems (system: {
      build = self.packages.${system}.default;
    });
  };
}
