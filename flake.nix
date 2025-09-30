{
  description = "Warp Terminal (preview) packaged from .deb on NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];
    forAll = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
  in {
    packages = forAll (pkgs:
      let
        debUrl = "https://app.warp.dev/get_warp?package=deb&channel=preview";
        debSha = "sha256-6/MvbgLuSkLLfS+ud0Av5fkeV7khbtJ9pmErIFduJvs=";
      in {
        default = pkgs.stdenv.mkDerivation {
          pname   = "warp-terminal-preview";
          version = "0.2025.09.24.08.13.preview.03";

          src = pkgs.fetchurl { url = debUrl; sha256 = debSha; };

          nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.dpkg pkgs.makeWrapper pkgs.file ];
          buildInputs = with pkgs; [
            stdenv.cc.cc zlib libGL
            xorg.libX11 xorg.libXext xorg.libXcursor xorg.libXi xorg.libXrandr xorg.libxcb
            libxkbcommon wayland gtk3 pango cairo fontconfig freetype libdrm
          ];

          unpackPhase = ''dpkg-deb -x $src .'';

          installPhase = ''
            mkdir -p $out
            cp -r usr/* $out/

            if [ -d "$out/bin" ]; then
              for b in "$out"/bin/*; do
                if [ -x "$b" ] && file -b "$b" | grep -q 'ELF'; then
                  wrapProgram "$b" --prefix PATH : /run/wrappers/bin
                fi
              done
            fi

            if [ -d "$out/share/applications" ] && [ -d "$out/bin" ]; then
              firstBin="$(basename "$(ls -1 "$out/bin" | head -n1 || true)")"
              if [ -n "$firstBin" ]; then
                for d in "$out/share/applications/"*.desktop; do
                  [ -f "$d" ] || continue
                  sed -i "s|^Exec=.*|Exec=$out/bin/$firstBin|" "$d" || true
                done
              fi
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