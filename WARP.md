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

### Automated (Recommended)

A GitHub Actions workflow automatically checks for updates daily:
- **Schedule**: Runs every day at 00:00 UTC
- **Manual trigger**: Can be triggered via GitHub Actions UI or CLI: `gh workflow run update-flake.yml`
- **Process**:
  1. Downloads latest Warp preview `.deb`
  2. Extracts version from package metadata
  3. Calculates SHA256 hash using `nix store prefetch-file`
  4. Updates both `version` and `debSha` in `flake.nix`
  5. Runs `nix flake update` to update nixpkgs
  6. Builds the package on `x86_64-linux` to verify
  7. Creates a PR with changes if there are updates
- **Location**: `.github/workflows/update-flake.yml`

**Phase 2 (Future)**: The workflow can be switched to auto-commit directly to main instead of creating PRs by uncommenting the direct commit section and commenting out the PR creation step.

### Manual

When you want to manually update or bypass automation:
1. Run `./update.sh` - this prefetches the new .deb, calculates its SRI hash, and updates `debSha` in `flake.nix`
2. The script validates the build automatically
3. The version field in `flake.nix` needs manual updating if you want it to reflect the actual Warp version
4. Commit changes to `flake.nix` and `flake.lock` (if updated)

## Font Configuration

Warp uses the system's fontconfig to discover fonts. The derivation does **not** bundle fonts - instead, it relies entirely on your system's font configuration. This means all fonts installed on your system will be available in Warp.

### Reproducible font installation (NixOS):

```nix
# In your configuration.nix or home-manager config
fonts.packages = with pkgs; [
  fira-code
  fira-code-nerdfont
  source-code-pro
  noto-fonts-color-emoji
  # Add any other fonts you want to use in Warp
];
```

### Alternative (user-level installation):

```bash
# Install fonts to your user profile
nix-env -iA nixpkgs.fira-code nixpkgs.source-code-pro nixpkgs.noto-fonts-color-emoji

# Or with nix profile
nix profile install nixpkgs#fira-code nixpkgs#source-code-pro nixpkgs#noto-fonts-color-emoji
```

### Verifying font availability:

```bash
# List all fonts visible to fontconfig
fc-list : family | sort | uniq

# Search for a specific font
fc-list | grep -i "fira"
```

After installing fonts:
1. The fonts should be immediately available via `fc-list`
2. Restart Warp completely (if it was running)
3. Go to Settings > Appearance
4. Check "View all available system fonts"
5. Your fonts should now appear in the dropdown

**Note**: If fonts still don't appear, ensure your system's fontconfig cache is up to date by running `fc-cache -fv`.

## Flake Structure Notes

- `inputs`: Only depends on nixpkgs unstable
- `outputs`: Provides `packages`, `apps`, and `checks` for supported systems
- `allowUnfree = true` is required since Warp is proprietary software
- The derivation uses a custom `installPhase` to handle the non-standard .deb layout
