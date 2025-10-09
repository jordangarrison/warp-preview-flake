# Contributing to warp-preview-flake

Thank you for your interest in contributing to the Warp Terminal preview flake! This document provides guidelines and information to help you contribute effectively.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Testing Your Changes](#testing-your-changes)
- [Submitting Changes](#submitting-changes)
- [Code Guidelines](#code-guidelines)
- [Update Process](#update-process)
- [Troubleshooting](#troubleshooting)

## Getting Started

This project packages the Warp Terminal preview `.deb` file as a Nix flake for NixOS systems. Before contributing, please:

1. Read the [WARP.md](./WARP.md) for project architecture and technical details
2. Ensure you have Nix with flakes enabled on your system
3. Familiarize yourself with basic Nix packaging concepts

### Prerequisites

- Nix 2.4+ with flakes enabled
- NixOS or Nix on Linux (x86_64-linux or aarch64-linux)
- Git for version control
- Basic understanding of Nix derivations and flake structure

## Development Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/warp-preview-flake.git
   cd warp-preview-flake
   ```

2. **Build the flake locally:**
   ```bash
   nix build .#default
   ```

3. **Test the built package:**
   ```bash
   ./result/bin/warp
   ```

4. **Enter development shell:**
   ```bash
   nix develop
   ```

## How to Contribute

### Reporting Issues

When reporting issues, please include:

- Your NixOS/Nix version (`nix --version`)
- System architecture (`uname -m`)
- Warp version from the flake (`nix flake show`)
- Complete error messages or unexpected behavior
- Steps to reproduce the issue

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:

- Check existing issues to avoid duplicates
- Clearly describe the enhancement and its benefits
- Provide use cases or examples
- Consider backward compatibility

### Areas for Contribution

We welcome contributions in these areas:

1. **Packaging improvements:**
   - Better dependency management
   - Improved binary patching
   - Performance optimizations

2. **Multi-architecture support:**
   - Testing on aarch64-linux
   - Addressing architecture-specific issues

3. **Documentation:**
   - Improving README or WARP.md
   - Adding examples or use cases
   - Clarifying installation steps

4. **Automation:**
   - Enhancing the update workflow
   - Adding more validation checks
   - Improving CI/CD processes

5. **Bug fixes:**
   - Resolving PATH issues
   - Fixing desktop integration problems
   - Addressing library dependency issues

## Testing Your Changes

Before submitting changes, ensure they pass all validations:

### 1. Build Test
```bash
nix build .#default --verbose
```

### 2. Flake Check
```bash
nix flake check
```

### 3. Run Test
```bash
nix run .
```

### 4. Test Critical Functionality

- **Verify sudo works:**
  ```bash
  ./result/bin/warp
  # Inside Warp terminal:
  sudo echo "test"
  ```

- **Check desktop integration:**
  ```bash
  cat result/share/applications/*.desktop
  # Verify Exec paths point to wrapped binary
  ```

- **Validate font access:**
  ```bash
  # Start Warp and check Settings > Appearance
  # Ensure system fonts appear in font selector
  ```

### 5. Multi-Architecture Testing (if applicable)

If your changes affect architecture-specific behavior:
```bash
# For x86_64-linux
nix build .#packages.x86_64-linux.default

# For aarch64-linux (if you have access)
nix build .#packages.aarch64-linux.default
```

## Submitting Changes

### Commit Message Guidelines

We follow conventional commit format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

**Examples:**
```
feat(packaging): add support for custom font directories

fix(wrapper): ensure /run/wrappers/bin is on PATH

docs(contributing): add testing guidelines

chore(update): bump Warp preview to version 0.2024.XX.YY
```

### Pull Request Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes and commit:**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

3. **Test thoroughly** (see [Testing Your Changes](#testing-your-changes))

4. **Push to your fork:**
   ```bash
   git push origin feat/your-feature-name
   ```

5. **Open a Pull Request:**
   - Provide a clear description of changes
   - Reference any related issues
   - Include testing steps
   - Note any breaking changes

6. **Address review feedback:**
   - Respond to comments promptly
   - Make requested changes
   - Push updates to the same branch

### PR Checklist

Before submitting, ensure:

- [ ] Code builds successfully (`nix build .#default`)
- [ ] Flake check passes (`nix flake check`)
- [ ] Application runs and critical features work
- [ ] Commit messages follow conventional format
- [ ] Documentation updated (if applicable)
- [ ] No unnecessary changes or files included
- [ ] Changes are backward compatible (or migration path provided)

## Code Guidelines

### Nix Style

- Use 2 spaces for indentation
- Keep lines under 100 characters when reasonable
- Use meaningful variable names
- Add comments for non-obvious logic
- Follow nixpkgs conventions

### Example Structure

```nix
# Good
let
  version = "0.2024.01.01.00.00.stable_00";
  
  src = fetchurl {
    url = "https://example.com/file.deb";
    hash = "sha256-...";
  };
in
stdenv.mkDerivation {
  pname = "warp-terminal";
  inherit version src;
  
  # Build inputs organized by category
  nativeBuildInputs = [ ... ];
  buildInputs = [ ... ];
  
  # Clear, documented phases
  installPhase = ''
    # Extract .deb without dpkg
    dpkg-deb -x $src unpacked
    
    # Install with proper structure
    ...
  '';
}
```

### Derivation Best Practices

1. **Explicit dependencies:** Declare all required runtime libraries
2. **PATH handling:** Ensure critical system paths are preserved
3. **Binary patching:** Use `autoPatchelfHook` appropriately
4. **Desktop integration:** Patch all `.desktop` files correctly
5. **Testing:** Validate that wrapped binaries work as expected

## Update Process

### Manual Updates

If you're updating the Warp version manually:

1. **Run the update script:**
   ```bash
   ./update.sh
   ```

2. **Verify the version:**
   ```bash
   nix eval .#packages.x86_64-linux.default.version
   ```

3. **Test the build:**
   ```bash
   nix build .#default && ./result/bin/warp
   ```

4. **Commit changes:**
   ```bash
   git add flake.nix flake.lock
   git commit -m "chore(update): bump Warp to version X.Y.Z"
   ```

### Automated Updates

The GitHub Actions workflow handles updates automatically. If you're modifying the workflow:

1. Test changes in a fork first
2. Validate the workflow syntax
3. Ensure proper error handling
4. Update documentation if behavior changes

## Troubleshooting

### Common Issues

**Build fails with "hash mismatch":**
- The .deb file has changed. Run `./update.sh` to update the hash.

**Application crashes on startup:**
- Check `LD_LIBRARY_PATH` is set correctly in the wrapper
- Verify all dependencies are declared in `buildInputs`
- Run with `nix run . --verbose` for detailed output

**Fonts don't appear:**
- This is a system configuration issue, not a packaging issue
- Direct users to the Font Configuration section in WARP.md

**Sudo doesn't work:**
- Verify `/run/wrappers/bin` is in PATH
- Check the wrapper script in `result/bin/warp`

### Getting Help

- Open an issue with detailed information
- Check existing issues for similar problems
- Review WARP.md for architecture details
- Ask in discussions (if enabled)

## Recognition

Contributors will be recognized in:
- Git commit history
- Release notes (for significant contributions)
- Special mentions for major features or fixes

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (check the repository for the specific license).

---

Thank you for contributing to warp-preview-flake! Your efforts help make Warp accessible to the NixOS community. 🚀
