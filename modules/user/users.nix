{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.user = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        fullName = mkOption {
          type = types.str;
          default = "System User";
          description = "Display name for the user";
        };
        shell = mkOption {
          type = types.enum [
            "zsh"
            "bash"
            "dash"
            "fish"
          ];
          default = "zsh";
          description = "Which shell should the user use";
        };
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to create and configure this user";
        };
      };
    });
    default = {};
    description = "User configurations for the system";
  };

  config = {
    # Create system users for each configured user
    users.users =
      mapAttrs (
        username: userConfig:
          mkIf userConfig.enable {
            description = userConfig.fullName;
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "systemd-journal"
              "input"
            ];
            shell = pkgs.${userConfig.shell};
          }
      )
      config.lamentos.user;

    # Enable required shell programs
    programs = mkMerge (
      mapAttrsToList (
        username: userConfig:
          mkIf userConfig.enable {
            ${userConfig.shell}.enable = true;
          }
      )
      config.lamentos.user
    );

    # Configure home-manager for each user
    home-manager.users =
      mapAttrs (
        username: userConfig:
          mkIf userConfig.enable {
            home.username = username;
            home.homeDirectory = "/home/${username}";
            programs.${userConfig.shell}.enable = true;
            home.shell.enableShellIntegration = true;
            home.stateVersion = config.lamentos.system.identity.stateVersion;
          }
      )
      config.lamentos.user;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
  };
}
