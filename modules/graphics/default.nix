{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.lamentos.graphics;
in {
  imports = [
    ./nvidia.nix # NVIDIA specific settings
  ];

  config = mkMerge [
    (mkIf cfg.nvidia.enable {
      services.xserver.videoDrivers = ["nvidia"];
      boot.initrd.kernelModules = ["nvidia"];

      hardware.nvidia = {
        modesetting.enable = true;
        open = cfg.nvidia.open;
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
    })
  ];
}
