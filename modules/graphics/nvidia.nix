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

  config = mkIf config.lamentos.graphics.nvidia.enable {
    services.xserver.videoDrivers = ["nvidia"];
    boot.initrd.kernelModules = ["nvidia"];

    hardware.nvidia = {
      modesetting.enable = true;
      open = config.lamentos.graphics.nvidia.open;
    };

    home-manager.sharedModules = [
      {
        home.sessionVariables = {
          # nvidia-specific environment variables
          LIBVA_DRIVER_NAME = "nvidia";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
        };
      }
    ];
  };
}
