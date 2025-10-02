{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.shell = {
    tools = mkOption {
      type = types.bool;
      default = true;
      description = "Should we use basic replacment tools (eza, bat, etc)";
    };
  };

  config =
    mkIf config.lamentos.shell.tools {
    };
}
