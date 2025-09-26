{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos = {
    system = {
      stateVersion = mkOption {
        type = types.str;
        default = "25.05";
        description = "The stateVersion we are using for the system. Unless you know what you're doing, DO NOT CHANGE THIS!";
      };
      systemType = mkOption {
        type = types.str;
        default = "x86_64-linux";
        description = "The system type we are using. You probably want to keep this as-is";
      };
      allowUnfree = mkOption {
        type = types.bool;
        default = true;
        description = "Should we allow 'unfree' software (and firmware)";
      };
    };
    hardware = {
      nvidia = {
        enable = mkEnableOption "Should we handle nvidia graphics cards";
        open = mkOption {
          type = types.bool;
          default = true;
          description = "Use the nvidia-open drivers";
        };
      };
    };
  };

  config = mkMerge [
    {
      system.stateVersion = config.lamentos.system.stateVersion;
      nixpkgs.hostPlatform = config.lamentos.system.systemType;
      nixpkgs.config.allowUnfree = config.lamentos.system.allowUnfree;
      hardware.enableRedistributableFirmware = config.lamentos.system.allowUnfree;
      home-manager.users.${config.lamentos.user.name}.home.stateVersion = config.lamentos.system.stateVersion;

      hardware.cpu.amd.updateMicrocode = config.lamentos.system.allowUnfree;
      hardware.cpu.intel.updateMicrocode = config.lamentos.system.allowUnfree;
    }
    (mkIf (config.lamentos.hardware.nvidia.enable == true) {
      services.xserver.videoDrivers = ["nvidia"];
      boot.initrd.kernelModules = ["nvidia"];
      boot.blacklistedKernelModules = ["nouveau"];

      boot.initrd.availableKernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      hardware.nvidia = {
        modesetting.enable = true;
        open = config.lamentos.hardware.nvidia.open;
        nvidiaSettings = false;
      };

      home-manager.users.${config.lamentos.user.name}.home.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
      };
    })
  ];
}
