{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkMerge mkIf mkDefault types;
  cfg = config.lamentos.system.theming;
in {
  options.lamentos.system.theming = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Should we provide a default theme across the system?";
    };

    useCustomTheme = mkOption {
      type = types.bool;
      default = config.lamentos.system.theming.enable;
      description = "Should we use our custom base24 theme across the system.";
    };

    fonts.monospace = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {type = types.package;};
          name = mkOption {type = types.str;};
        };
      };
      default = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono Nerd Font";
      };
      description = "Monospace font couplet for the system";
    };
    fonts.sansSerif = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {type = types.package;};
          name = mkOption {type = types.str;};
        };
      };
      default = {
        package = pkgs.fira;
        name = "Fira Sans";
      };
      description = "SansSerif font couplet for the system";
    };
    fonts.serif = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {type = types.package;};
          name = mkOption {type = types.str;};
        };
      };
      default = {
        package = pkgs.crimson;
        name = "Crimson Pro";
      };
      description = "Serif font couplet for the system";
    };

    cursor = mkOption {
      type = types.submodule {
        options = {
          package = mkOption {type = types.package;};
          name = mkOption {type = types.str;};
          size = mkOption {type = types.int;};
        };
      };
      default = {
        package = pkgs.numix-cursor-theme;
        name = "Numix-Cursor-Light";
        size = 36;
      };
      description = "Cursor triplet for the system";
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      stylix = {
        enable = true;
        # If we are not using our custom theme, let's default to catppuccin-mocha
        base16Scheme =
          if cfg.useCustomTheme
          then ./lamentos.yaml
          else mkDefault "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

        fonts = {
          monospace = {
            package = cfg.fonts.monospace.package;
            name = cfg.fonts.monospace.name;
          };
          sansSerif = {
            package = cfg.fonts.sansSerif.package;
            name = cfg.fonts.sansSerif.name;
          };
          serif = {
            package = cfg.fonts.serif.package;
            name = cfg.fonts.serif.name;
          };
          sizes = mkDefault {
            applications = 14;
            desktop = 12;
          };
        };

        cursor = {
          package = cfg.cursor.package;
          name = cfg.cursor.name;
          size = cfg.cursor.size;
        };
      };
    })
  ];
}
