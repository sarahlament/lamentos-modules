# NixOS Module System: Config Block Patterns and Best Practices

Research findings on how NixOS modules handle configuration blocks, based on analysis of LamentOS codebase, nixpkgs, home-manager, and official documentation.

**Related:** For file organization patterns (single-file vs separated, aggregator patterns), see [DEFAULT_NIX_PATTERNS.md](./DEFAULT_NIX_PATTERNS.md).

---

## Table of Contents

1. [Config Block Structure Patterns](#config-block-structure-patterns)
2. [Priority System (mkDefault/mkForce/mkOverride)](#priority-system)
3. [Conditional Configuration Best Practices](#conditional-configuration-best-practices)
4. [Common Patterns](#common-patterns)
5. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
6. [When to Use mkDefault](#when-to-use-mkdefault)
7. [Decision Matrices](#decision-matrices)
8. [Real-World Examples](#real-world-examples)

---

## Config Block Structure Patterns

### Pattern A: Single `mkIf` Block

**Use case:** Single enable flag with all configuration dependent on that flag.

```nix
# Example: modules/graphics/default.nix
config = mkMerge [
  (mkIf config.lamentos.graphics.nvidia.enable {
    services.xserver.videoDrivers = ["nvidia"];
    boot.initrd.kernelModules = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      open = config.lamentos.graphics.nvidia.open;
    };
  })
];
```

**Why `mkMerge` with single block?** Only when you'll add more blocks later (e.g., graphics/ will add AMD/Intel drivers, shell/ will add aliases/prompt). Don't use for simple leaf modules (single enable flag) or unconditional glue logic (pure pass-through).

### Pattern B: Multiple `mkIf` Blocks within `mkMerge`

**Use case:** Multiple independent features that can be enabled separately.

```nix
# Example: modules/system/theming/default.nix
config = mkMerge [
  (mkIf (config.lamentos.system.theming.enable) {
    stylix = {
      enable = true;
      base16Scheme = mkIf (config.lamentos.system.theming.useCustomTheme) ./lamentos.yaml;
      fonts = { ... };
      cursor = { ... };
    };
  })
  (mkIf (config.lamentos.system.theming.omp.enable) {
    stylix.override = { ... };
    home-manager.sharedModules = [ ... ];
  })
];
```

### Pattern C: Flat Config without Conditionals

**Use case:** Non-optional system configuration that always applies.

```nix
# Example: modules/system/default.nix
config = {
  system.stateVersion = config.lamentos.system.identity.stateVersion;
  nixpkgs.hostPlatform = config.lamentos.system.identity.systemType;
  nixpkgs.config.allowUnfree = config.lamentos.system.identity.allowUnfree;
  networking.hostName = config.lamentos.system.identity.hostName;

  networking.networkmanager.enable = mkDefault true;
};
```

### Pattern D: `mapAttrs` with Inline `mkIf`

**Use case:** Creating multiple similar resources (users, services, etc.).

```nix
# Example: modules/user/default.nix
config = {
  users.users = mapAttrs (
    username: userConfig:
      mkIf userConfig.enable {
        description = userConfig.fullName;
        isNormalUser = true;
        extraGroups = ["wheel" "systemd-journal" "input"];
        shell = pkgs.${userConfig.shell};
      }
  ) config.lamentos.user;
};
```

---

## Priority System

### Priority Levels (Lower Number = Higher Priority)

- **1500**: `mkOptionDefault` - Lowest priority, for option defaults
- **1000**: `mkDefault` - Default values that can be easily overridden
- **100**: Normal priority (no modifier)
- **50**: `mkForce` - Force a value, overriding almost everything
- **10**: `mkOrder 10` - Custom high priority

### When to Use Each

#### `mkDefault`

Use for implementation details that users might want to override:

```nix
# Convenience defaults
networking.networkmanager.enable = mkDefault true;

# Reasonable default values
fonts.sizes = mkDefault {
  applications = 14;
  desktop = 12;
};

# Hardware-specific settings
hardware.nvidia.modesetting.enable = mkDefault true;
```

#### `mkForce`

Use sparingly, only when you must override values from multiple modules:

```nix
# Fixing conflicts between modules
security.sudo.enable = mkForce false;  # When enabling sudo-rs
```

**Warning:** Avoid `mkForce` in reusable modules - it prevents downstream customization.

#### No Modifier (Normal Priority)

Use for:
- Direct option pass-through
- Tightly coupled values
- Required system state
- Values that should conflict if set elsewhere

```nix
# Direct pass-through - NO mkDefault
stylix.fonts.monospace = {
  package = config.lamentos.system.theming.fonts.monospace.package;
  name = config.lamentos.system.theming.fonts.monospace.name;
};

# Tightly coupled values - NO mkDefault
stylix.override = {
  base0F = "d8a8f0";
  base10 = "98d898";
  # ... these must stay synchronized
};
```

---

## Conditional Configuration Best Practices

### Nested `mkIf` Patterns

#### Block-Level `mkIf`

Use for entire feature blocks:

```nix
config = mkMerge [
  (mkIf cfg.mainFeature {
    # All main feature config here
    someOption = "value";
    anotherOption = "value";
  })
];
```

#### Inline `mkIf`

Use for individual options with sub-conditions:

```nix
config = mkMerge [
  (mkIf cfg.enable {
    stylix = {
      enable = true;
      # Inline mkIf for sub-feature
      base16Scheme = mkIf cfg.useCustomTheme ./lamentos.yaml;
    };
  })
];
```

### `if/then` vs `mkIf`

#### Use `if/then` when you need an `else` branch:

```nix
config = {
  services.resolved.dnssec =
    if config.my.custom.opt.dnssecforced
    then "true"
    else "allow-downgrade";
};
```

#### Use `mkIf` for conditional inclusion:

```nix
config = mkIf cfg.enable {
  warnings = ["foo"];
};
```

**Critical difference:** `mkIf` prevents infinite recursion when the condition references `config`, while `if/then` can cause infinite recursion at the block level.

### Handling Main Flag + Sub-Features

```nix
options.lamentos.system.theming = {
  enable = mkOption {
    type = types.bool;
    default = true;
  };

  # Sub-feature defaults to main enable
  useCustomTheme = mkOption {
    type = types.bool;
    default = config.lamentos.system.theming.enable;
  };

  omp.enable = mkOption {
    type = types.bool;
    default = config.lamentos.system.theming.enable;
  };
};

config = mkMerge [
  # Main feature block
  (mkIf (config.lamentos.system.theming.enable) {
    stylix = {
      enable = true;
      # Sub-feature uses inline mkIf
      base16Scheme = mkIf (config.lamentos.system.theming.useCustomTheme) ./lamentos.yaml;
    };
  })

  # Independent sub-feature block
  (mkIf (config.lamentos.system.theming.omp.enable) {
    # omp-specific config
  })
];
```

**Pattern:** Main feature in outer `mkIf`, sub-features can use either:
1. Separate `mkMerge` block (if substantial config)
2. Inline `mkIf` within main block (if small/related config)

### Tightly-Coupled Configuration

When values must stay synchronized:

```nix
(mkIf (config.lamentos.system.theming.omp.enable) {
  # All base24 colors defined together - tightly coupled
  # NO mkDefault - these must stay synchronized
  stylix.override = {
    base0F = "d8a8f0"; # REPURPOSED: neutral/metadata
    base10 = "98d898"; # STATUS: success/healthy
    base11 = "e0d088"; # STATUS: warning/attention
    # ... all related colors in one block
  };

  home-manager.sharedModules = [{
    programs.oh-my-posh = {
      settings = {
        palette = {
          # These MUST reference the stylix values
          active_focus = config.lib.stylix.colors.withHashtag.base14;
          system_info = config.lib.stylix.colors.withHashtag.base17;
        };
      };
    };
  }];
})
```

**Best practices for tightly-coupled options:**
1. **Keep together:** All related values in same `mkIf` block
2. **No mkDefault:** Tightly coupled values should NOT use `mkDefault`
3. **Single source of truth:** Reference the authoritative source
4. **Document relationships:** Comments explaining why values are coupled

---

## Common Patterns

### The "cfg" Variable Pattern

Universal in nixpkgs, makes code cleaner:

```nix
let
  cfg = config.lamentos.graphics.nvidia;
in {
  options.lamentos.graphics.nvidia = { ... };

  config = mkIf cfg.enable {
    # Much cleaner than repeating full path
  };
}
```

### The "Let with Helper Functions" Pattern

```nix
let
  cfg = config.services.foo;

  configFile = pkgs.writeText "foo.conf" ''
    ${cfg.setting1}
    ${cfg.setting2}
  '';

  mkUserConfig = username: {
    home.file.".foo".source = configFile;
  };
in {
  config = mkIf cfg.enable {
    home-manager.users = mapAttrs (n: v: mkUserConfig n) cfg.users;
  };
}
```

### Assertions for Conflict Prevention

```nix
config = mkIf cfg.enable {
  assertions = [{
    assertion = !config.security.sudo.enable;
    message = "sudo and sudo-rs cannot both be enabled";
  }];

  # ... rest of config
};
```

---

## Anti-Patterns to Avoid

### ❌ Anti-Pattern 1: Using `if/then` for Block-Level Conditionals

```nix
# WRONG - causes infinite recursion
config = if config.foo then {
  warnings = ["foo"];
} else {};

# RIGHT
config = mkIf config.foo {
  warnings = ["foo"];
};
```

### ❌ Anti-Pattern 2: Mixing `optionalAttrs` at Top Level

```nix
# WRONG - can cause infinite recursion
config = {
  services.foo = { enable = true; }
  // optionalAttrs config.bar.enable {
    extraConfig = "...";
  };
};

# RIGHT
config = mkMerge [
  { services.foo.enable = true; }
  (mkIf config.bar.enable {
    services.foo.extraConfig = "...";
  })
];
```

### ❌ Anti-Pattern 3: Using `mkForce` in Reusable Modules

```nix
# WRONG - prevents downstream customization
config = mkIf cfg.enable {
  services.foo.setting = mkForce "value";
};

# RIGHT - use mkDefault or no modifier
config = mkIf cfg.enable {
  services.foo.setting = mkDefault "value";  # If overridable
  # or
  services.foo.setting = "value";  # If normal priority
};
```

### ❌ Anti-Pattern 4: Not Using `mkMerge` for Extensibility

```nix
# WORKS but not extensible
config = mkIf cfg.enable {
  # All config here
};

# BETTER - easy to add more conditions later (IF you'll add them)
config = mkMerge [
  (mkIf cfg.enable {
    # Config here
  })
  # Will add more conditional blocks as features grow
];
```

**Note:** Use `mkMerge` only for modules that will have multiple conditional features. Simple leaf modules (single enable flag), unconditional glue logic, and inline `mkIf` within `mapAttrs` don't need `mkMerge`.

### ❌ Anti-Pattern 5: Using `mkDefault` for Direct Option Pass-Through

```nix
# WRONG - these should be direct pass-through
stylix.fonts.monospace = {
  package = mkDefault config.lamentos.system.theming.fonts.monospace.package;
  name = mkDefault config.lamentos.system.theming.fonts.monospace.name;
};

# RIGHT - direct pass-through at normal priority
stylix.fonts.monospace = {
  package = config.lamentos.system.theming.fonts.monospace.package;
  name = config.lamentos.system.theming.fonts.monospace.name;
};
```

---

## When to Use mkDefault

### ✅ Use `mkDefault` For:

1. **Convenience defaults** - Features that improve UX but users may want different:
   ```nix
   networking.networkmanager.enable = mkDefault true;
   ```

2. **Implementation details with reasonable defaults:**
   ```nix
   fonts.sizes = mkDefault {
     applications = 14;
     desktop = 12;
   };
   ```

3. **Hardware/platform-specific settings:**
   ```nix
   hardware.nvidia.modesetting.enable = mkDefault true;
   ```

4. **Security features that might need exceptions:**
   ```nix
   security.lockKernelModules = mkDefault true;
   ```

### ❌ Do NOT Use `mkDefault` For:

1. **Direct option pass-through** - User's options should be respected at normal priority
2. **Tightly coupled values** - Values that must stay synchronized
3. **Required system state** - Critical configuration that shouldn't be overridden
4. **Values that should conflict if set elsewhere** - Let the module system detect conflicts

---

## Decision Matrices

### Block-Level vs Inline `mkIf` Decision Matrix

| Scenario | Use Block-Level `mkIf` | Use Inline `mkIf` |
|----------|------------------------|-------------------|
| Entire feature can be disabled | ✓ | |
| Individual option has sub-condition | | ✓ |
| Multiple options share condition | ✓ | |
| Single value has unique condition | | ✓ |
| Need else branch | Use `if/then` instead | Use `if/then` instead |

### Pattern Selection Matrix

| Pattern | Use Case | Example |
|---------|----------|---------|
| `config = { ... }` | Non-optional config | System identity settings |
| `config = mkIf cfg.enable { ... }` | Single optional feature | Desktop environment |
| `config = mkMerge [(mkIf ...) ...]` | Multiple optional features | Theming system |
| `mkDefault value` | Overridable implementation detail | NetworkManager enable |
| No `mkDefault` | Direct pass-through or required | Font packages, cursor |
| Inline `mkIf` | Sub-feature condition | Custom theme file |
| `mapAttrs` with `mkIf` | Multi-instance pattern | User creation |
| Tightly-coupled block | Synchronized values | Theme colors + palette |

---

## Real-World Examples

### Example 1: sudo-rs.nix (nixpkgs Security Module)

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.security.sudo-rs;
in {
  options.security.sudo-rs = {
    enable = lib.mkEnableOption "memory-safe sudo implementation";

    wheelNeedsPassword = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    # Assertion to prevent conflicts
    assertions = [{
      assertion = !config.security.sudo.enable;
      message = "sudo and sudo-rs cannot both be enabled";
    }];

    # Using mkDefault to allow override
    security.sudo.enable = lib.mkDefault false;

    # Using mkMerge with mkOrder for rule ordering
    security.sudo-rs.extraRules = lib.mkMerge [
      (lib.mkOrder 400 (defaultRule { users = [ "root" ]; }))
      (lib.mkOrder 600 (defaultRule {
        groups = [ "wheel" ];
        opts = (lib.optional (!cfg.wheelNeedsPassword) "NOPASSWD");
      }))
    ];
  };
}
```

### Example 2: pcscd.nix (nixpkgs Service Module)

```nix
config = lib.mkIf config.services.pcscd.enable {
  systemd.services.pcscd = {
    environment = {
      PCSCLITE_HP_DROPDIR = pluginEnv;
      # Inline mkIf for conditional env var
      PCSCLITE_FILTER_IGNORE_READER_NAMES = lib.mkIf (cfg.ignoreReaderNames != [ ])
        (lib.concatStringsSep ":" cfg.ignoreReaderNames);
    };
  };
};
```

### Example 3: LamentOS KDE Module

```nix
{ config, lib, pkgs, ... }:
with lib; {
  options.lamentos.desktop.plasma6 = {
    enable = mkEnableOption "Enable the plasma6 Desktop Environment";
  };

  config = mkIf config.lamentos.desktop.plasma6.enable {
    # XDG portal setup
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
      xdgOpenUsePortal = true;
    };

    # Services configuration
    services = {
      dbus.enable = true;
      xserver.enable = true;
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    # System packages
    environment.systemPackages = with pkgs; [
      kdePackages.kcalc
      kdePackages.filelight
      haruna
    ];

    # Disable conflicting styling
    stylix.targets.qt.enable = false;
  };
}
```

---

## Summary: LamentOS Module System Analysis

### What LamentOS Does Right ✅

1. ✓ Clean option namespace under `lamentos.*`
2. ✓ Separation of options files and implementation
3. ✓ Using `mkMerge` even for single blocks (extensibility)
4. ✓ Proper use of `mkDefault` (sparingly, only for implementation details)
5. ✓ Correct handling of tightly-coupled config (base24 colors)
6. ✓ Good use of `mapAttrs` for multi-user pattern
7. ✓ Using `cfg` variable pattern in newer modules
8. ✓ Inline `mkIf` for sub-features within main blocks
9. ✓ Direct pass-through without `mkDefault` for user options
10. ✓ Documented relationships for complex configurations

### Suggestions for Consistency

1. **Add `cfg` variable** to modules that don't have it yet:
   ```nix
   let
     cfg = config.lamentos.graphics.nvidia;
   in {
     config = mkMerge [
       (mkIf cfg.enable {
         # ... cleaner references
       })
     ];
   }
   ```

2. **Consider adding assertions** for conflicting options where applicable

3. **Continue documenting** tightly-coupled sections with comments

---

## Quick Reference

### Common Imports

```nix
{ config, lib, pkgs, ... }:
with lib; {
  # Your module here
}
```

### Standard Module Structure

```nix
let
  cfg = config.path.to.your.option;
in {
  imports = [ ./options.nix ];

  config = mkMerge [
    (mkIf cfg.enable {
      # Main config
    })
  ];
}
```

### Recommended Reading

- [NixOS Manual: Writing Modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [nixpkgs source](https://github.com/NixOS/nixpkgs/tree/master/nixos/modules)
- [home-manager source](https://github.com/nix-community/home-manager/tree/master/modules)

---

*Research compiled from: LamentOS codebase analysis, nixpkgs source code, NixOS manual, and community best practices.*
*Last updated: 2025-10-07*
