{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos = {
    hardware = {
      nvidia = {
        enable = mkEnableOption "Should we handle nvidia graphics cards";
        open = mkOption {
          type = types.bool;
          default = true;
          description = "Use the nvidia-open drivers";
        };
      };
      audio = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable audio support";
        };
        pipewire = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable PipeWire audio server";
          };
          pulse = mkOption {
            type = types.bool;
            default = true;
            description = "Enable PulseAudio compatibility layer for PipeWire";
          };
          alsa = mkOption {
            type = types.bool;
            default = true;
            description = "Enable ALSA support for PipeWire";
          };
          wireplumber = mkOption {
            type = types.bool;
            default = true;
            description = "Enable WirePlumber session manager for PipeWire";
          };
        };
      };
    };
  };

  config = mkMerge [
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
    (mkIf (config.lamentos.hardware.audio.enable == true) {
      services.pipewire = mkIf (config.lamentos.hardware.audio.pipewire.enable == true) {
        enable = true;
        pulse.enable = config.lamentos.hardware.audio.pipewire.pulse;
        alsa.enable = config.lamentos.hardware.audio.pipewire.alsa;
        wireplumber.enable = config.lamentos.hardware.audio.pipewire.wireplumber;
      };
    })
  ];
}