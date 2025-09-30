# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Nix flake that packages the Warp Terminal preview `.deb` file into a Nix derivation for NixOS systems. The packaging uses `dpkg-deb -x` for extraction and `autoPatchelfHook` for binary patching. A critical feature is ensuring `/run/wrappers/bin` is on PATH so `sudo` works inside Warp.

## Architecture

**Single-derivation flake structure:**
- `flake.nix` - Main flake definition containing the derivation
- `update.sh` - Script to fetch latest preview .deb and update the SHA hash
- Multi-arch support: `x86_64-linux` and `aarch64-linux`

**Key packaging details:**
- Source: Downloads `.deb` from `https://app.warp.dev/download?channel=preview&package=deb`
- Extraction: Uses `dpkg-deb -x` to unpack the .deb without dpkg installation
- Binary patching: `autoPatchelfHook` handles dynamic library dependencies
- Wrapper: `makeWrapper` ensures PATH includes `/run/wrappers/bin` and sets LD_LIBRARY_PATH
- Desktop integration: Patches `.desktop` files to use the wrapped binary

**Dependencies:**
The derivation requires various X11/Wayland libraries (libGL, libxkbcommon, wayland, gtk3, etc.) which are declared in `buildInputs`.

## Common Commands

### Build and run locally
```bash
# Build the package
nix build .#default

# Run directly
./result/bin/warp

# Or build and run in one step
nix run .
```

### Update to latest preview version
```bash
# Fetches latest .deb, updates SHA in flake.nix, and validates build
./update.sh

# Then run the updated version
nix run .
```

### Validate the build
```bash
# Run the flake check
nix flake check
```

### Development/debugging
```bash
# Build verbosely to see build phases
nix build .#default --verbose

# Enter a development shell with build dependencies
nix develop

# Show flake metadata
nix flake metadata

# Show package info
nix flake show
```

## Update Workflow

When Warp releases a new preview version:
1. Run `./update.sh` - this prefetches the new .deb, calculates its SRI hash, and updates `debSha` in `flake.nix`
2. The script validates the build automatically
3. The version field in `flake.nix` may need manual updating if you want it to reflect the actual Warp version
4. Commit changes to `flake.nix` and `flake.lock` (if updated)

## Flake Structure Notes

- `inputs`: Only depends on nixpkgs unstable
- `outputs`: Provides `packages`, `apps`, and `checks` for supported systems
- `allowUnfree = true` is required since Warp is proprietary software
- The derivation uses a custom `installPhase` to handle the non-standard .deb layout