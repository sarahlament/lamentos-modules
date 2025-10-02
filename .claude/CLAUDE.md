# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Flake Management
- `nix flake check` - Validate flake configuration for syntax errors
- `nix flake show` - Display available flake outputs
- `nix flake update` - Update all flake inputs to latest versions
- `alejandra .` - Format Nix files using Alejandra formatter

## Architecture Overview

This is the **LamentOS module system** - a reusable NixOS module system designed to be imported as a flake input by other NixOS configurations.

### Repository Structure

```
~/.lamentos/
├── flake.nix              # Module system flake definition
└── modules/
    ├── default.nix        # Aggregates all module imports
    ├── graphics/          # Graphics hardware configuration
    ├── system/            # System-level modules (identity, theming)
    ├── user/              # Multi-user management
    └── shell/             # Shell-related modules
```

### Key Architecture Principles

- **Clean option namespace**: All options live under `lamentos.*` (e.g., `lamentos.graphics.nvidia.enable`)
- **Separation of concerns**: Options files define configuration API, implementation files handle NixOS details
- **Module composition**: Each module focuses on a specific domain
- **Flake-based distribution**: Exposes `nixosModules.default` output for consumption by other flakes
- **Home Manager integration**: Modules can configure both system and user-level settings via `home-manager.sharedModules`

### Module Pattern

LamentOS modules follow a consistent pattern:

1. **Options module** (e.g., `nvidia.nix`): Defines `options.lamentos.*` using `mkOption`
2. **Implementation module** (`default.nix`): Defines `config.*` using the lamentos options
3. **Aggregation** (`default.nix` at parent level): Imports related modules

Example structure:
```nix
# Options file - defines API
{ lib, ... }:
with lib; {
  options.lamentos.graphics.nvidia = {
    enable = mkOption { ... };
    open = mkOption { ... };
  };
}

# Implementation file - uses options
{ config, lib, ... }:
with lib; {
  imports = [ ./nvidia.nix ];

  config = mkMerge [
    (mkIf config.lamentos.graphics.nvidia.enable {
      # Actual NixOS configuration here
    })
    # Easy to add more conditional blocks without refactoring
  ];
}
```

### Code Style

- Use `with lib;` for cleaner option definitions
- Wrap config blocks in `mkIf` + `mkMerge` even if there's only one block - makes adding more blocks later easier without refactoring
- Use `mapAttrs` for multi-user/multi-item patterns
- Keep options and implementation separate
- Document options with `description` field
