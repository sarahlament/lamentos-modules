# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Flake Management
- `nix flake check` - Validate flake configuration for syntax errors
- `nix flake show` - Display available flake outputs
- `nix flake update` - Update all flake inputs to latest versions
- `alejandra .` - Format Nix files using Alejandra formatter

**Important:** Do NOT run `nix flake check` after every change - configuration errors only surface during actual system builds, not flake validation.

## Project Philosophy

### Core Mission
LamentOS is a **desktop/workstation-focused** NixOS module system providing a "distro-level" experience. The goal: users configure a working system in a few lines, then customize from there.

### Design Principles

**"It Just Works" by default**
- Sensible defaults for 90% of users
- Advanced users can override anything with `mkDefault`
- Errors should have helpful, casual messages

**Transparent but not prescriptive**
- We wrap external modules (home-manager, stylix) for convenience
- Users should manage their own version pins via `inputs.*.follows`
- We accept the maintenance of keeping dependencies compatible
- Philosophy: Framework for integration, users provide the versions

**Target audience: Desktop users**
- Not optimized for servers or headless systems
- Assertions enforce desktop requirements (e.g., graphics drivers)
- Documentation speaks to beginners, implementation serves power users

**Minimal privilege by default**
- Regular users get no special groups (systemd-logind handles device access)
- Admin status is explicit opt-in
- Security warnings are prominent, not preachy

## Architecture Overview

### Repository Structure

```
~/.lamentos/
├── flake.nix              # Wraps dependencies, exposes nixosModules
├── .claude/               # AI assistant guidance
└── modules/
    ├── default.nix        # Imports home-manager/stylix + all modules
    ├── desktop/           # Desktop environments (KDE, etc.)
    ├── graphics/          # GPU drivers (NVIDIA, Intel, AMD)
    ├── shell/             # Shell tools and configurations
    ├── system/            # System identity, theming, core settings
    └── user/              # Multi-user management
```

### Key Architectural Decisions

**Module Wrapping:**
`modules/default.nix` imports home-manager and stylix modules. Users get functionality without managing every input, but should override versions via `inputs.*.follows` for proper version control.

**Option Namespace:**
All options live under `lamentos.*` to avoid conflicts. Use descriptive names that make the purpose clear.

**Vendor Selection Pattern:**
Hardware features use top-level enum selectors (e.g., `graphics.vendor = "nvidia"`) with vendor-specific suboptions. This enforces mutual exclusivity while keeping organization clean.

## Module Organization Patterns

LamentOS uses five patterns based on **feature relationships**. See [DEFAULT_NIX_PATTERNS.md](./.claude/DEFAULT_NIX_PATTERNS.md) for detailed examples.

### The Five Patterns

#### 1. Leaf Modules (Single Feature)
- **When:** Single, focused functionality
- **Structure:** One file with options + config
- **Key trait:** Simple `mkIf`, no `mkMerge`

#### 2. Pure Aggregators (Independent Siblings)
- **When:** Multiple independent features
- **Structure:** Only imports, no config block
- **Key trait:** Each import is self-contained

#### 3. Aggregator + Implementation (Related Features)
- **When:** Features sharing implementation patterns
- **Structure:** Imports + `mkMerge` with multiple `mkIf` blocks
- **Key trait:** One block per feature variant
- **Examples:** `graphics/` (GPU drivers), `shell/` (tools)

#### 4. Aggregator + Shared Config (Coordination)
- **When:** Features need coordination/glue logic
- **Structure:** Imports + flat `config = { }`
- **Key trait:** Unconditional pass-through config
- **Examples:** `system/` (coordinates identity/theming), `user/` (creates users)

#### 5. Complex Multi-Feature
- **When:** Many sub-concerns in one domain
- **Structure:** `default.nix` + multiple settings files
- **Key trait:** Multiple option files by concern
- **Examples:** `system/theming/` (fonts, colors, cursors)

### Pattern Selection Decision Tree

1. Single feature? → **Leaf Module** (#1)
2. Multiple independent features? → **Pure Aggregator** (#2)
3. Related features with similar config patterns? → **Aggregator + Implementation** (#3)
4. Need coordination between children? → **Aggregator + Shared Config** (#4)
5. Many sub-concerns in one domain? → **Complex Multi-Feature** (#5)

## Code Style Guidelines

### Consistency Rules
- Use explicit `inherit (lib) ...` imports instead of `with lib;`
  - List all required lib functions in the let binding for clarity
  - This improves LSP support, makes dependencies explicit, and aligns with nixpkgs best practices
  - Example: `inherit (lib) mkIf mkMerge mkDefault mkEnableOption mkOption types;`
- Always define `cfg` variable for module config
- Separate options (API) from implementation (config)
- Document all options with clear descriptions

### When to Use mkMerge
Only when you have multiple conditional blocks. If you can't envision a second condition, just use `mkIf` directly.

**Rule of thumb:** mkMerge implies "more conditions will be added" - use it to signal extensibility.

### Using mkDefault
Use `mkDefault` for any value users might reasonably override. Internal plumbing (groups, paths, package references) should not use `mkDefault`.

## Development Workflow

### Adding New Features

1. Choose appropriate pattern based on feature relationships
2. Create options in separate file unless leaf module
3. Use `cfg` variable for cleaner code
4. Add assertions for hard requirements with helpful messages
5. Test by rebuilding an actual system configuration
6. Update README if user-facing

## Flake Input Management

### Our Position
- We provide home-manager and stylix integration
- Users MUST manage their own nixpkgs (we don't support our pins)
- Users SHOULD manage home-manager/stylix versions via `follows`
- We maintain compatibility, users control versions

### Philosophy
We're a framework for module integration, not a distribution. Users provide the package versions, we provide the "glue" that makes modules work together.

## Remember

- Target audience: desktop/workstation users
- "It just works" beats "perfectly secure" for our use case
- Helpful error messages > technically accurate but cryptic ones
- Defaults serve 90%, options serve the remaining 10%
- When in doubt, be explicit rather than clever
