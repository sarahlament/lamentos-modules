{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.shell.modernTools = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Should we use modern replacement tools (eza, bat, fd, ripgrep, etc)";
    };
  };
}
