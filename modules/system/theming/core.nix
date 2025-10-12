{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
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
  };
}
