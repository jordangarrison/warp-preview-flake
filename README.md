# Warp Terminal (preview) – NixOS flake

Packages Warp preview `.deb` into a Nix derivation with `dpkg-deb -x` + `autoPatchelf`.
Ensures `/run/wrappers/bin` is on PATH so `sudo` works inside Warp.

## Build & Run
```bash
nix build .#default
./result/bin/warp
# or:
nix run .
```

## Install system-wide

### NixOS

```nix
inputs.warp-preview.url = "github:<youruser>/warp-preview";
environment.systemPackages = [
  inputs.warp-preview.packages.${pkgs.system}.default
];
```

### Home Manager

```nix
home.packages = [
  inputs.warp-preview.packages.${pkgs.system}.default
];
```

## Updates

Automatically updated daily via GitHub Actions. Manual: `./update.sh` or `gh workflow run update-flake.yml`
