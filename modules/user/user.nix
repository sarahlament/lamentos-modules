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
}
