{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.graphics.nvidia = {
    enable = mkEnableOption "Should we handle nvidia graphics cards";

    open = mkOption {
      type = types.bool;
      default = true;
      description = "Use the nvidia-open drivers";
    };
  };
}
