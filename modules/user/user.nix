{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types;
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
}
