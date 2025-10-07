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

# Implementation file - uses options (Aggregator + Implementation pattern)
{ config, lib, ... }:
with lib; {
  imports = [ ./nvidia.nix ];

  config = mkMerge [
    (mkIf config.lamentos.graphics.nvidia.enable {
      # Actual NixOS configuration here
    })
    # Will add more blocks for AMD/Intel drivers later
  ];
}
```

### Code Style

- Use `with lib;` for cleaner option definitions
- Use `mkMerge` only when you'll add more conditional blocks (see "When to Use mkMerge" below)
- Use `mapAttrs` for multi-user/multi-item patterns
- Keep options and implementation separate
- Document options with `description` field

### When to Use mkMerge

Use `mkMerge` when you will add more conditional blocks:

**Use mkMerge for:**
- Aggregator + Implementation modules (graphics/, shell/) - will add multiple feature blocks
- Multi-feature modules (theming/) - has multiple enable flags with separate blocks
- Any module where you'll add conditional blocks later

**Don't use mkMerge for:**
- Simple leaf modules with single enable flag (kde.nix) - just use `mkIf` directly
- Aggregator + Shared Config with unconditional glue logic (system/) - flat `config = { }` is cleaner
- Modules using inline `mkIf` within `mapAttrs` for per-entity conditionals (user/)

**Rule of thumb:** If you can't envision adding a second `(mkIf ...)` block, don't wrap in `mkMerge`.

## Module Organization Patterns

LamentOS uses patterns based on **feature relationships**, not completion state. See [DEFAULT_NIX_PATTERNS.md](./.claude/DEFAULT_NIX_PATTERNS.md) for comprehensive details.

### The Five Patterns

#### 1. Leaf Modules (Single Feature)
- **Structure:** Single file with options + config
- **Use for:** Focused, single-purpose modules
- **Examples:** `nvidia.nix`, `kde.nix`, `identity.nix`
- **Pattern:** Just `mkIf` directly, no `mkMerge` needed

#### 2. Pure Aggregators (Independent Siblings)
- **Structure:** Pure imports only
- **Use for:** Features that are independent of each other
- **How it expands:** Add completely new independent modules
- **Examples:** `desktop/default.nix` (will add GNOME, Hyprland independently)
- **Pattern:** No config block, just imports

#### 3. Aggregator + Implementation (Related Features)
- **Structure:** Imports + config with multiple `mkIf` blocks
- **Use for:** Features sharing implementation patterns
- **How it expands:** Add related features with similar config blocks
- **Examples:** `graphics/default.nix` (GPU drivers), `shell/default.nix` (shell tools)
- **Pattern:** `config = mkMerge [(mkIf ...) (mkIf ...)]`

#### 4. Aggregator + Shared Config (Coordination)
- **Structure:** Imports + glue logic config
- **Use for:** Features needing coordination between children's options
- **Examples:** `system/default.nix`, `user/default.nix`
- **Pattern:** Flat `config = { }` with unconditional pass-through

#### 5. Complex Multi-Feature
- **Structure:** `default.nix` + multiple option files
- **Use for:** Modules with multiple sub-features organized by concern
- **Examples:** `system/theming/`
- **Pattern:** Multiple option files imported, implementation in default.nix

### Pattern Selection Guide

**Ask: How will features relate?**
- Independent siblings → Pure Aggregator (#2)
- Related with shared patterns → Aggregator + Implementation (#3)
- Need coordination/glue → Aggregator + Shared Config (#4)

**Always use:**
- `cfg` variable for cleaner references
- Pattern that reflects how features will expand
- Comments to document tightly-coupled sections
