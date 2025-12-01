{
  description = "Warp Terminal (preview) packaged from .deb on NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAll = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    }));
  in {
    packages = forAll (pkgs:
      let
        debUrl = "https://app.warp.dev/download?channel=preview&package=deb";
        debSha = "sha256-zNVAsx6HkULkeJKBGLztyKljLOhGTPRLUssUKi+/Yl8=";
      in {
        default = pkgs.stdenv.mkDerivation {
          pname   = "warp-terminal-preview";
          version = "0.2025.11.19.08.12.preview.05";

          src = pkgs.fetchurl {
            url = debUrl;
            sha256 = debSha;
            curlOptsList = [ "-L" ];
            name = "warp-preview.deb";
          };

          nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.dpkg pkgs.makeWrapper pkgs.file ];
          buildInputs = with pkgs; [
            stdenv.cc.cc zlib libGL curl alsa-lib
            xorg.libX11 xorg.libXext xorg.libXcursor xorg.libXi xorg.libXrandr xorg.libxcb
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
                pkgs.libGL pkgs.libxkbcommon pkgs.wayland pkgs.xorg.libX11
                pkgs.xorg.libXcursor pkgs.xorg.libXi pkgs.xorg.libXrandr
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
      };
    });

    checks = nixpkgs.lib.genAttrs systems (system: {
      build = self.packages.${system}.default;
    });
  };
}