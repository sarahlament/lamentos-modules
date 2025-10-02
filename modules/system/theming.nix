{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.system.theming = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Should we provide a default theme across the system?";
    };
    useCustomTheme = mkOption {
      type = types.bool;
      default = true;
      description = "Should we use our custom base24 theme across the system.";
    };
  };

  # Small thing: we are setting a LOT of defaults here, some of which are not 'configurable'
  # through this module system as they use more complex settings. For ease of use, I use mkDefault
  # where appropriate so that the user can override with their own stylix settings
  config = mkMerge [
    {
      stylix = {
        enable = config.lamentos.system.theming.enable;

        cursor = mkDefault {
          name = "Numix-Cursor-Light";
          package = pkgs.numix-cursor-theme;
          size = 32;
        };

        fonts = {
          monospace = mkDefault {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrains Mono Nerd Font";
          };
          sansSerif = mkDefault {
            package = pkgs.fira;
            name = "Fira Sans";
          };
          serif = mkDefault {
            package = pkgs.crimson;
            name = "Crimson Pro";
          };
          sizes = mkDefault {
            applications = 14;
            desktop = 12;
          };
        };
      };
    }
    (mkIf config.lamentos.system.theming.useCustomTheme {
      stylix.base16Scheme = mkDefault {
        # LamentOS base16 colors (tweaked purple intensity)
        base00 = "110115"; # Dark purple background
        base01 = "110115"; # Reduced purple saturation
        base02 = "1f0428"; # Less intense
        base03 = "6a4a7a"; # Lighter purple for better comment visibility
        base04 = "3a0a4a"; # Softer purple
        base05 = "d0c0d8"; # Much lighter for better text readability
        base06 = "5a1569"; # Gentler progression
        base07 = "6b1a7a"; # Less bright endpoint
        base08 = "ed7a43"; # Orange (errors/variables)
        base09 = "a2a71d"; # Yellow-green (numbers/constants)
        base0A = "51ca3e"; # Green (classes/search)
        base0B = "29cf93"; # Cyan-green (strings)
        base0C = "40b3ea"; # Blue (functions/methods)
        base0D = "8a86ff"; # Purple (keywords)
        base0E = "db63ef"; # Pink-purple (storage/selectors)
        base0F = "db63ef"; # DEPRECATED but expected to be here?

        # LamentOS base24 extensions (complement the purple theme)
        base10 = "b8860b"; # Darker gold
        base11 = "1e5a3a"; # Dark forest green
        base12 = "2c1810"; # Dark brown
        base13 = "4a1c4a"; # Muted purple-magenta
        base14 = "8b4513"; # Saddle brown
        base15 = "1a472a"; # Deep green
        base16 = "2f1b2f"; # Dark plum
        base17 = "3a1a1a"; # Dark burgundy
      };
    })
  ];
}
