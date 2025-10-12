{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types;
  inherit (lib) mkIf mkMerge mkDefault mapAttrs mapAttrsToList;
  cfg = config.lamentos.user;
  cfgs = config.lamentos.users;
  syscfg = config.lamentos.system;
in {
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
        isAdmin = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this user should have admin rights";
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
  options.lamentos.users.sudoNoPassword = mkEnableOption "Should sudo work without a password";

  config = {
    # Create system users for each configured user
    users.users =
      mapAttrs (
        username: userConfig:
          mkIf userConfig.enable {
            description = userConfig.fullName;
            isNormalUser = true;
            initialHashedPassword = mkDefault "$6$p20S/Lmo4mac8WYC$LcJ1.Shd2nqNms10afnhD6//Nm3gn7HdHZlZwsNCx2bYFRC.iNyHU5vbRpo96FOV33JuMyxV32izMy8zW89mP1";
            extraGroups = mkIf userConfig.isAdmin ["wheel" "systemd-journal"];
            shell = pkgs.${userConfig.shell};
          }
      )
      cfg;

    # Enable required shell programs
    programs = mkMerge (
      mapAttrsToList (
        username: userConfig:
          mkIf userConfig.enable {
            ${userConfig.shell}.enable = true;
          }
      )
      cfg
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
            home.stateVersion = syscfg.identity.stateVersion;
          }
      )
      cfg;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    # This is in fact correct. sudoNoPasword defaults to false, which is what this needs to work correcrly, so we need the inverse of the option. We set both, since if modernTools.useRustSudo is false sudo-rs isn't used at all
    security.sudo.wheelNeedsPassword = !(cfgs.sudoNoPassword);
    security.sudo-rs.wheelNeedsPassword = !(cfgs.sudoNoPassword);
  };
}
