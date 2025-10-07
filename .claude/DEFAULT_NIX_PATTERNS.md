# NixOS Module Organization: The default.nix Question

Comprehensive research on how `default.nix` files should be organized in NixOS module systems.

**Related:** For config block patterns (mkIf, mkMerge, mkDefault usage), see [NIXOS_MODULE_PATTERNS.md](./NIXOS_MODULE_PATTERNS.md).

---

## Table of Contents

1. [The Five Patterns](#the-five-patterns)
2. [Pattern Comparison](#pattern-comparison)
3. [LamentOS Current State](#lamentos-current-state)
4. [Decision Matrix](#decision-matrix)
5. [Module Evolution Path](#module-evolution-path)
6. [Recommendations for LamentOS](#recommendations-for-lamentos)
7. [Real-World Examples](#real-world-examples)
8. [Trade-offs Analysis](#trade-offs-analysis)

---

## Key Insight: Structure Reflects Feature Relationships

**The pattern you choose should reflect how features relate to each other, not their completion state.**

All modules can expand, but they expand differently:

- **Pure aggregator** → Features are independent siblings (desktop environments)
- **Aggregator + implementation** → Features share implementation patterns (GPU drivers, shell tools)
- **Aggregator + shared config** → Features need coordination/glue logic (system identity + theming)

Your module structure documents expansion intent. When someone sees `graphics/default.nix` with implementation, they know: "This will grow by adding related features with similar config patterns."

---

## The Five Patterns

### Pattern 1: Single-File Module (Options + Config Together)

**Most common in nixpkgs and home-manager** (90% of modules)

```nix
# nvidia.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.lamentos.graphics.nvidia;
in {
  options.lamentos.graphics.nvidia = {
    enable = mkEnableOption "NVIDIA graphics support";
    open = mkOption {
      type = types.bool;
      default = false;
      description = "Use open-source kernel modules";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.xserver.videoDrivers = ["nvidia"];
      hardware.nvidia = {
        modesetting.enable = true;
        open = cfg.open;
      };
    })
  ];
}
```

**When to use:**
- Module has focused, single purpose
- Options and implementation are tightly coupled
- Module is unlikely to grow dramatically (< 150 lines)
- Simplicity is prioritized

**Examples from LamentOS:**
- `desktop/kde.nix`
- `shell/modernTools.nix`
- `system/identity.nix`

**Examples from nixpkgs:**
- `services/networking/ssh/sshd.nix`
- `programs/nano.nix`
- Most services and programs

---

### Pattern 2: Separated Options Pattern

**Used for complex modules** (10% of nixpkgs, common in large projects)

```
module-name/
├── default.nix    # Implementation + imports options
├── options.nix    # Option declarations only
└── test.nix       # Tests (optional)
```

**options.nix:**
```nix
{ lib, ... }:

with lib; {
  options.myModule = {
    enable = mkEnableOption "My Module";

    setting1 = mkOption {
      type = types.str;
      description = "Setting 1";
    };

    setting2 = mkOption {
      type = types.int;
      default = 42;
    };
  };
}
```

**default.nix:**
```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.myModule;
in {
  imports = [ ./options.nix ];

  config = mkMerge [
    (mkIf cfg.enable {
      # Implementation here
    })
  ];
}
```

**When to use:**
- Module has many options (10+)
- Options are reused in multiple places (`types.submodule`)
- Clear API/implementation separation needed
- Multiple contributors working on same module
- Module is > 200 lines

**Examples:**
- nixcloud-webservices reverse-proxy
- Complex enterprise modules
- Public APIs

---

### Pattern 3: Pure Aggregator

**Common for namespace organization**

```nix
# modules/default.nix
{ ... }:
{
  imports = [
    ./system
    ./user
    ./graphics
    ./shell
    ./desktop
  ];
}
```

**When to use:**
- Organizing related modules into namespaces
- Root-level module aggregation
- Directory contains multiple independent modules
- No shared configuration needed

**Examples from LamentOS:**
- `modules/default.nix` (root)
- `modules/desktop/default.nix`

---

### Pattern 4: Aggregator + Shared Config

**Used when parent needs to coordinate children**

```nix
# modules/system/default.nix
{ config, lib, pkgs, ... }:

with lib; {
  imports = [
    ./identity.nix
    ./theming
  ];

  # Flat config - unconditional glue logic, no mkMerge needed
  config = {
    # Pass through identity settings
    system.stateVersion = config.lamentos.system.identity.stateVersion;
    nixpkgs.hostPlatform = config.lamentos.system.identity.systemType;
    nixpkgs.config.allowUnfree = config.lamentos.system.identity.allowUnfree;
    networking.hostName = config.lamentos.system.identity.hostName;

    # Convenience default
    networking.networkmanager.enable = mkDefault true;
  };
}
```

**When to use:**
- Parent module needs to coordinate child modules
- Shared configuration across child modules
- Common defaults or glue logic needed

**Examples from LamentOS:**
- `system/default.nix`
- `user/default.nix`

---

### Pattern 5: Aggregator + Implementation

**Used when parent coordinates related features with shared patterns**

```nix
# modules/graphics/default.nix
{ config, lib, pkgs, ... }:

with lib; {
  imports = [
    ./nvidia.nix
    # Future: ./amd.nix, ./intel.nix
  ];

  config = mkMerge [
    (mkIf config.lamentos.graphics.nvidia.enable {
      services.xserver.videoDrivers = ["nvidia"];
      hardware.nvidia = {
        modesetting.enable = true;
        open = config.lamentos.graphics.nvidia.open;
      };
    })
    # Future: (mkIf config.lamentos.graphics.amd.enable { ... })
  ];
}
```

**When to use:**
- Related features that share implementation patterns
- Will add multiple feature blocks over time (AMD/Intel drivers, shell tools)
- Each feature has similar config structure
- Default.nix coordinates common patterns across features

**Examples from LamentOS:**
- `graphics/default.nix` (will add AMD/Intel drivers)
- `shell/default.nix` (will add aliases/prompt/env vars)

**Key distinction from Pattern 4:** Pattern 4 (Shared Config) has unconditional glue logic, while Pattern 5 has conditional feature blocks with `mkMerge`.

---

## Pattern Comparison

### Quick Reference Table

| Pattern | Options Location | Config Location | Best For | Lines of Code |
|---------|-----------------|-----------------|----------|---------------|
| **Single-File** | Same file | Same file | Focused modules | < 150 |
| **Separated** | `options.nix` | `default.nix` | Complex modules | > 200 |
| **Pure Aggregator** | Child modules | Child modules | Independent siblings | N/A |
| **Aggregator + Shared Config** | Child modules | `default.nix` flat | Coordination/glue | Varies |
| **Aggregator + Implementation** | Child modules | `default.nix` mkMerge | Related features | Varies |

### Module Complexity Guide

| Complexity | Options Count | Lines | Recommended Pattern |
|-----------|---------------|-------|---------------------|
| Simple | 1-3 | < 50 | Single-File |
| Moderate | 4-10 | 50-150 | Single-File |
| Complex | 10-20 | 150-300 | Single-File OR Separated* |
| Very Complex | 20+ | 300+ | Separated |
| Multi-Feature | Varies | Varies | default.nix + Multiple Options |

*Use Separated if options are reused in `types.submodule`

---

## LamentOS Current State

### Pattern Consistency Analysis (Intentional Design)

**Different patterns for different feature relationships:**

```
graphics/
├── default.nix (imports nvidia.nix + has config)
└── nvidia.nix (options only)
→ Related features with shared implementation patterns
→ Will add AMD/Intel drivers with similar config blocks

shell/
├── default.nix (imports modernTools.nix + has config)
└── modernTools.nix (options only)
→ Related features with shared implementation patterns
→ Will add aliases/prompt/etc with similar patterns

desktop/
├── default.nix (pure aggregator, just imports)
└── kde.nix (options + config together)
→ Independent siblings
→ Will add other desktop environments (GNOME, Hyprland, etc)
```

**Key insight:** Pattern choice reflects **how features relate to each other**:
- **Pure aggregator** = Independent siblings (desktop environments)
- **Aggregator + implementation** = Related features sharing patterns (GPU drivers, shell tools)
- **Aggregator + shared config** = Features needing glue logic (system, user)

Everything can expand, but they expand differently based on feature relationships.

---

## Decision Matrix

### When to Use Single-File

✅ **Use when:**
- Module is self-contained
- < 150 lines of code
- 1-10 options
- Options tightly coupled to implementation
- Solo developer or small team
- Simplicity is important

❌ **Don't use when:**
- Options reused in `types.submodule`
- > 200 lines of code
- Multiple sub-features
- Public API needs clear documentation

### When to Use Separated Options

✅ **Use when:**
- Module > 200 lines
- Options used in `types.submodule`
- Multiple implementations share options
- Public/reusable module
- Team collaboration
- Clear API documentation needed

❌ **Don't use when:**
- Simple module < 150 lines
- Options not reused
- Solo developer on private module
- Simplicity more important than separation

### When to Use Pure Aggregator

✅ **Use when:**
- Organizing category of modules
- No shared config needed
- Root-level aggregation
- Namespace organization

❌ **Don't use when:**
- Need shared configuration
- Need coordination between children
- Only one child module (just import directly)

### When to Use Aggregator + Shared Config

✅ **Use when:**
- Parent needs to coordinate children
- Shared defaults across children
- Glue logic needed
- Children's options used together

❌ **Don't use when:**
- No shared config needed (use pure aggregator)
- Only one child (merge or use single-file)

---

## Module Evolution Path

### Stage 1: Simple Single-File (Start Here)

**Example:** LamentOS `identity.nix`

```nix
{ config, lib, ... }:

with lib; {
  options.lamentos.system.identity = {
    hostName = mkOption {
      type = types.str;
      default = "nixos";
    };
    stateVersion = mkOption {
      type = types.str;
      default = "25.11";
    };
  };

  config = {
    networking.hostName = config.lamentos.system.identity.hostName;
    system.stateVersion = config.lamentos.system.identity.stateVersion;
  };
}
```

**Characteristics:**
- ~30 lines
- 2 options
- Simple implementation
- Easy to understand

**Stay here if:** Module remains simple and focused

---

### Stage 2: Growing Single-File

**Example:** LamentOS `kde.nix`

```nix
{ config, lib, pkgs, ... }:

with lib; {
  options.lamentos.desktop.plasma6 = {
    enable = mkEnableOption "Enable the plasma6 Desktop Environment";
  };

  config = mkIf config.lamentos.desktop.plasma6.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
    };

    services = {
      xserver.enable = true;
      displayManager.sddm.enable = true;
    };

    environment.systemPackages = with pkgs; [
      kdePackages.kcalc
      kdePackages.filelight
    ];
  };
}
```

**Characteristics:**
- ~50 lines
- 1 enable option
- Moderate implementation
- Still clear structure

**Stay here if:** < 150 lines and no option reuse needed

---

### Stage 3: Complex Multi-Feature (Split into Directory)

**When to refactor:** Multiple sub-features or > 150 lines

**Example:** LamentOS `system/theming/`

```
theming/
├── default.nix      # Implementation + imports
├── core.nix         # Core options (enable, useCustomTheme)
└── _settings.nix    # Feature-specific options (fonts, cursor, omp)
```

**default.nix:**
```nix
{ config, lib, pkgs, ... }:

with lib; {
  imports = [
    ./core.nix
    ./_settings.nix
  ];

  config = mkMerge [
    (mkIf config.lamentos.system.theming.enable {
      # Basic theming config
    })
    (mkIf config.lamentos.system.theming.omp.enable {
      # oh-my-posh config
    })
  ];
}
```

**Characteristics:**
- Multiple option files by concern
- Implementation in default.nix
- Multiple conditional blocks
- Easy to add features

**Use this when:**
- Multiple enable flags
- Organized sub-features
- Each feature has distinct options

---

### Stage 4: Very Complex with Reusable Options

**When to refactor:** Options used in `types.submodule` or > 300 lines

**Example:** nixcloud reverse-proxy

```
reverse-proxy/
├── default.nix    # Implementation
├── options.nix    # Reusable submodule options
└── test.nix       # Tests
```

**options.nix:**
```nix
{ lib, ... }:

with lib; {
  options = {
    domain = mkOption { ... };
    port = mkOption { ... };
    path = mkOption { ... };
  };
}
```

**default.nix:**
```nix
{ config, lib, ... }:

with lib;

let
  cfg = config.nixcloud.reverse-proxy;

  # Options reused as submodule
  mappingOpts = import ./options.nix { inherit lib; };
in {
  options.nixcloud.reverse-proxy = {
    enable = mkEnableOption "reverse proxy";

    mappings = mkOption {
      type = types.listOf (types.submodule mappingOpts);
    };
  };

  config = mkIf cfg.enable {
    # Complex implementation
  };
}
```

**Use this when:**
- Options reused in submodules
- Very complex implementation (300+ lines)
- Public API needs clear documentation
- Multiple contributors

---

## Recommendations for LamentOS

### Standardized Pattern Guide

Based on your architecture and stated principles, here's the recommended standard:

#### 1. Leaf Modules (Single Feature)

**Pattern:** Single-file with options + config together

**Use for:**
- `nvidia.nix`
- `kde.nix`
- `identity.nix`
- `modernTools.nix`
- Any new single-purpose module

**Template:**
```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.lamentos.category.feature;
in {
  options.lamentos.category.feature = {
    enable = mkEnableOption "feature description";
    # More options
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Implementation
    })
  ];
}
```

#### 2. Category Aggregators (No Shared Config)

**Pattern:** Pure imports only

**Use for:**
- `modules/default.nix` (already correct)
- `desktop/default.nix` (already correct)
- Any new category without shared config

**Template:**
```nix
{ ... }:
{
  imports = [
    ./module1.nix
    ./module2.nix
    ./subdir  # Auto-imports subdir/default.nix
  ];
}
```

#### 3. Parent Coordinators (Shared Config Needed)

**Pattern:** Imports + shared config

**Use for:**
- `system/default.nix` (already correct)
- `user/default.nix` (already correct)
- Any parent that coordinates children

**Template:**
```nix
{ config, lib, pkgs, ... }:

with lib; {
  imports = [
    ./child1.nix
    ./child2
  ];

  config = {
    # Shared config using child options
    system.foo = config.lamentos.system.child1.bar;
  };
}
```

#### 4. Complex Multi-Feature Modules

**Pattern:** default.nix + multiple option files

**Use for:**
- `system/theming/` (already correct)
- Any module with multiple sub-features
- Modules where options organize by concern

**Template:**
```
feature/
├── default.nix        # Implementation
├── core.nix          # Core options
└── subfeature.nix    # Sub-feature options
```

### Current Structure is Correct ✅

The existing patterns are intentionally chosen based on feature relationships. No fixes needed.

#### graphics/default.nix - Aggregator + Implementation (Correct)

**Current:**
```
graphics/
├── default.nix (imports + config)
└── nvidia.nix (options only)
```

**Why this pattern:**
- Will add AMD/Intel drivers later
- All drivers share similar config patterns (videoDrivers, kernel modules, etc)
- default.nix will have multiple `mkIf` blocks for each driver

**Future expansion:**
```nix
config = mkMerge [
  (mkIf cfg.nvidia.enable { ... })
  (mkIf cfg.amd.enable { ... })     # Future
  (mkIf cfg.intel.enable { ... })   # Future
];
```

#### shell/default.nix - Aggregator + Implementation (Correct)

**Current:**
```
shell/
├── default.nix (imports + config)
└── modernTools.nix (options only)
```

**Why this pattern:**
- Will add aliases, prompt, etc later
- Related shell features share implementation patterns
- default.nix will have multiple `mkIf` blocks for each feature

**Future expansion:**
- Aliases module
- Prompt module (might move omp from theming)
- Shell-specific environment vars

#### Minor Improvement: Add cfg Variable Consistently

**Current:** Some modules use full paths, others use `cfg`

**Recommendation:** Add to all modules that don't have it:

```nix
let
  cfg = config.lamentos.graphics.nvidia;
in {
  config = mkMerge [
    (mkIf cfg.enable {  # Much cleaner
      # ...
    })
  ];
}
```

### Documentation Update

Add to `CLAUDE.md`:

```markdown
## Module Organization Patterns

LamentOS uses patterns based on **feature relationships**, not completion state:

### 1. Leaf Modules (Single Feature)
- **Structure:** Single file with options + config
- **Use for:** Focused, single-purpose modules
- **Examples:** `nvidia.nix`, `kde.nix`, `identity.nix`

### 2. Pure Aggregators (Independent Siblings)
- **Structure:** Pure imports only
- **Use for:** Features that are independent of each other
- **How it expands:** Add completely new independent modules
- **Examples:** `desktop/default.nix` (will add GNOME, Hyprland independently)

### 3. Aggregator + Implementation (Related Features)
- **Structure:** Imports + config with multiple `mkIf` blocks
- **Use for:** Features sharing implementation patterns
- **How it expands:** Add related features with similar config blocks
- **Examples:** `graphics/default.nix` (GPU drivers), `shell/default.nix` (shell tools)

### 4. Aggregator + Shared Config (Coordination)
- **Structure:** Imports + glue logic config
- **Use for:** Features needing coordination between children's options
- **Examples:** `system/default.nix`, `user/default.nix`

### 5. Complex Multi-Feature
- **Structure:** `default.nix` + multiple option files
- **Use for:** Modules with multiple sub-features organized by concern
- **Examples:** `system/theming/`

### Pattern Selection Guide

**Ask: How will features relate?**
- Independent siblings → Pure Aggregator (#2)
- Related with shared patterns → Aggregator + Implementation (#3)
- Need coordination/glue → Aggregator + Shared Config (#4)

**Always use:**
- `cfg` variable for cleaner references
- `mkMerge` even for single blocks (extensibility)
- Comments to document tightly-coupled sections
- Pattern that reflects how features will expand
```

---

## Real-World Examples

### Example 1: nixpkgs sshd.nix (Single-File)

**Size:** ~500 lines (but well-organized)

**Structure:**
```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.openssh;
  # ... helper functions
in {
  options = {
    services.openssh = {
      enable = mkEnableOption "OpenSSH daemon";
      # ... 30+ options
    };
  };

  config = mkIf cfg.enable {
    # Implementation
  };
}
```

**Why single-file?**
- Options tightly coupled to implementation
- No reuse of options elsewhere
- Well-organized with helper functions

### Example 2: home-manager git.nix (Single-File)

**Size:** ~200 lines

**Structure:**
```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.git;
in {
  options.programs.git = {
    enable = mkEnableOption "Git";
    # ... 15 options
  };

  config = mkIf cfg.enable {
    # Implementation
  };
}
```

**Why single-file?**
- Moderate complexity
- Clear structure
- No option reuse

### Example 3: nixcloud reverse-proxy (Separated)

**Size:** ~800 lines total

**Structure:**
```
reverse-proxy/
├── default.nix (600 lines)
├── options.nix (150 lines)
└── test.nix (50 lines)
```

**options.nix:**
```nix
{ lib, ... }:

{
  options = {
    domain = mkOption { ... };
    path = mkOption { ... };
    # ... 15+ options for mapping
  };
}
```

**default.nix:**
```nix
{ config, lib, ... }:

let
  cfg = config.nixcloud.reverse-proxy;

  # Import reusable options
  mappingOpts = import ./options.nix { inherit lib; };
in {
  options.nixcloud.reverse-proxy = {
    mappings = mkOption {
      type = types.listOf (types.submodule mappingOpts);  # Reuse!
    };
  };

  config = {
    # Complex implementation
  };
}
```

**Why separated?**
- Options reused in `types.submodule`
- Very complex implementation
- Clear API for users
- Public module

### Example 4: LamentOS theming (Multi-Feature)

**Size:** ~300 lines total

**Structure:**
```
theming/
├── default.nix (230 lines - implementation)
├── core.nix (20 lines - core options)
└── _settings.nix (50 lines - feature options)
```

**Why this pattern?**
- Multiple sub-features (fonts, cursor, omp)
- Options organized by concern
- Implementation has multiple `mkIf` blocks
- Easy to add new features

**Excellent pattern for this use case!**

---

## Trade-offs Analysis

### Single-File Pattern

#### Pros ✅
- Simple to understand
- Everything in one place
- Less file navigation
- Fast to write
- Good for small modules
- Lower cognitive overhead

#### Cons ❌
- Can become unwieldy (300+ lines)
- Hard to separate API from implementation
- Difficult to reuse options
- Git diffs harder with mixed changes
- Can be harder to review

#### Best For
- Leaf modules
- Single-purpose features
- < 150 lines
- Private/internal modules
- Solo developer

---

### Separated Options Pattern

#### Pros ✅
- Clear API/implementation separation
- Options file serves as documentation
- Easy to reuse options (submodules)
- Better for large modules
- Better for team collaboration
- Cleaner git diffs (API vs implementation changes)
- Easier to review

#### Cons ❌
- More files to navigate
- Context switching between files
- Overkill for simple modules
- More boilerplate
- Higher initial complexity

#### Best For
- Complex modules (> 200 lines)
- Reusable options (`types.submodule`)
- Public APIs
- Team collaboration
- When API documentation is important

---

### Pure Aggregator Pattern

#### Pros ✅
- Clean namespace organization
- Simple to understand
- Easy to add/remove modules
- Clear structure for large projects
- Separation of concerns

#### Cons ❌
- Can't add shared config (need different pattern)
- Requires convention (children must be self-contained)
- Extra file for simple cases

#### Best For
- Category directories
- Root-level modules
- Namespace organization
- When children are independent

---

### Aggregator + Shared Config Pattern

#### Pros ✅
- Combines aggregation with coordination
- Reduces duplication
- Clear parent/child relationship
- Good for hierarchical modules
- Enables shared defaults

#### Cons ❌
- Mixing concerns (aggregation + implementation)
- Can become cluttered if not careful
- Less clear than pure aggregation
- Harder to understand at first glance

#### Best For
- Parent modules that coordinate children
- Shared configuration needed
- Glue logic between modules
- Using children's options together

---

## Summary & Quick Guide

### The Golden Rules

1. **Start simple** - Single file for new modules
2. **Refactor when needed** - Don't over-engineer early
3. **Be consistent** - Use same pattern for similar modules
4. **Document patterns** - Make conventions explicit

### Quick Decision Tree

```
New module needed?
│
├─ Single feature, < 150 lines?
│  └─ → Use Single-File Pattern
│
├─ Multiple features or > 150 lines?
│  └─ → Use default.nix + Multiple Options
│
├─ Options reused in types.submodule?
│  └─ → Use Separated Options Pattern
│
├─ Organizing multiple modules?
│  │
│  ├─ How will they relate?
│  │  │
│  │  ├─ Independent siblings (desktop envs, etc)?
│  │  │  └─ → Use Pure Aggregator
│  │  │
│  │  ├─ Related features sharing patterns (drivers, tools)?
│  │  │  └─ → Use Aggregator + Implementation
│  │  │
│  │  └─ Need coordination/glue logic?
│  │     └─ → Use Aggregator + Shared Config
```

### LamentOS Patterns (Based on Feature Relationships)

| Pattern | When to Use | Example | How It Expands |
|---------|-------------|---------|----------------|
| **Single-file** | Focused feature | `nvidia.nix`, `kde.nix` | Grows in same file |
| **Pure aggregator** | Independent siblings | `desktop/` | Add new independent modules |
| **Aggregator + implementation** | Related features | `graphics/`, `shell/` | Add `mkIf` blocks for related features |
| **Aggregator + shared config** | Coordination needed | `system/`, `user/` | Add glue logic between children |
| **Multi-file complex** | Multiple sub-features | `theming/` | Add option files by concern |

### What LamentOS Does Right ✅

1. ✓ Single-file for focused modules
2. ✓ Pure aggregators for independent siblings
3. ✓ Aggregator + implementation for related features (graphics, shell)
4. ✓ Aggregator + shared config for coordination (system, user)
5. ✓ Multi-file for complex features (theming)
6. ✓ Consistent use of `mkMerge` + `mkIf` even for single blocks
7. ✓ Structure documents feature relationships and expansion intent

### Minor Improvements

1. Add `cfg` variable consistently across all modules
2. Document these patterns in CLAUDE.md (see Documentation Update section above)

---

## Best Practices from Community

### From nixpkgs

1. **Prefer single-file** until complexity demands separation
2. **Use `cfg` variable** for cleaner code
3. **Document options well** - they're your API
4. **Keep it simple** - don't over-engineer

### From home-manager

1. **Single-file is fine** even at 200+ lines if well-organized
2. **Separate only when** options are reused
3. **Use submodules** for repeated patterns

### From Enterprise Projects

1. **Separate early** for public modules
2. **Options are API** - treat them as documentation
3. **Test complex modules** - add test.nix
4. **Clear separation** helps team collaboration

---

## Conclusion

The NixOS ecosystem primarily uses **single-file modules** (90%+). Separation is the exception, not the rule, used only when:

- Options are reused (`types.submodule`)
- Module is very complex (300+ lines)
- Public API needs clear documentation
- Team collaboration requires clear separation

**LamentOS is exceptionally well-structured.** The patterns are intentionally chosen based on **feature relationships**:
- **Pure aggregator** for independent siblings (`desktop/`)
- **Aggregator + implementation** for related features with shared patterns (`graphics/`, `shell/`)
- **Aggregator + shared config** for coordination/glue logic (`system/`, `user/`)
- **Multi-file complex** for multiple sub-features organized by concern (`theming/`)

**Key principles:**
1. Pattern choice reflects how features will expand and relate to each other
2. Structure documents intent (independent vs related vs coordinated)
3. Wrapping config in `mkIf + mkMerge` even for single blocks enables easy extension
4. Start simple (single-file), refactor when relationships become clear

---

*Research compiled from: LamentOS codebase, nixpkgs source, home-manager source, nixcloud-webservices, NixOS manual, and community best practices.*

*Last updated: 2025-10-07*
