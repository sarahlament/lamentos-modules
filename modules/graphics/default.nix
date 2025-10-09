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
    ./settings.nix # Options blocks
  ];

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.vendor != null;
          message = "So, we kinda need to know what graphics driver you need...";
        }
      ];
      home-manager.sharedModules = [
        {
          home.sessionVariables = {
            ELECTRON_OZONE_PLATFORM_HINT = "auto";
          };
        }
      ];
    }
    (mkIf (cfg.vendor == "nvidia") {
      services.xserver.videoDrivers = ["nvidia"];
      boot.initrd.kernelModules = ["nvidia"];

      hardware.nvidia = {
        modesetting.enable = true;
        open = cfg.nvidia.open;
      };

      environment.systemPackages = mkIf cfg.nvidia.cuda.enable [
        cfg.nvidia.cuda.package
      ];

      home-manager.sharedModules = [
        {
          home.sessionVariables = mkMerge [
            {
              # nvidia-specific enviro`nment variables
              LIBVA_DRIVER_NAME = "nvidia";
              VDPAU_DRIVER = "nvidia";
              __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            }
            (mkIf cfg.nvidia.cuda.enable {
              CUDA_PATH = "${cfg.nvidia.cuda.package}";
            })
          ];
        }
      ];
    })

    (mkIf (cfg.vendor == "intel") {
      services.xserver.videoDrivers = ["modesetting"];
      boot.initrd.kernelModules = ["i915"];

      environment.systemPackages = with pkgs; [
        (
          if cfg.intel.vaapiDriver == "iHD"
          then intel-media-driver
          else intel-vaapi-driver
        )
        (mkIf cfg.intel.openCL intel-compute-runtime)
      ];

      home-manager.sharedModules = [
        {
          home.sessionVariables = {
            # Intel hardware acceleration
            LIBVA_DRIVER_NAME = cfg.intel.vaapiDriver;
            VDPAU_DRIVER = "va_gl";
          };
        }
      ];
    })

    (mkIf (cfg.vendor == "amd") {
      services.xserver.videoDrivers = ["amdgpu"];
      boot.initrd.kernelModules = ["amdgpu"];

      environment.systemPackages = with pkgs; [
        # Vulkan driver
        (mkIf (cfg.amd.vulkanDriver == "amdvlk") amdvlk)

        # OpenCL support
        (mkIf cfg.amd.openCL.enable (
          if cfg.amd.openCL.backend == "rocm"
          then rocmPackages.clr
          else mesa.opencl
        ))
      ];

      home-manager.sharedModules = [
        {
          home.sessionVariables = {
            # AMD hardware acceleration
            LIBVA_DRIVER_NAME = "radeonsi";
            VDPAU_DRIVER = "radeonsi";

            # Set Vulkan driver if using AMDVLK
            AMD_VULKAN_ICD = mkIf (cfg.amd.vulkanDriver == "amdvlk") "AMDVLK";
          };
        }
      ];
    })
  ];
}
