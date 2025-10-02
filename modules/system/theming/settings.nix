{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.system.theming = {
    omp.enable = mkOption {
      type = types.bool;
      default = config.lamentos.system.theming.enable;
      description = "Should we use a shell prompt theme as well";
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
        size = 34;
      };
      description = "Cursor triplet for the system";
    };
  };
}
