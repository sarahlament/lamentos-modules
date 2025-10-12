{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types;
  inherit (lib) mkIf mkMerge;
  cfg = config.lamentos.graphics;
in {
  options.lamentos.graphics = {
    vendor = mkOption {
      type = types.nullOr (types.enum [
        "nvidia"
        "intel"
        "amd"
      ]);
      default = null;
      description = "Which graphics driver should we enable";
    };

    nvidia = {
      open = mkOption {
        type = types.bool;
        default = true;
        description = "Use the nvidia-open drivers";
      };
      cuda = {
        enable = mkEnableOption "Enable CUDA support";
        package = mkOption {
          type = types.package;
          default = pkgs.cudaPackages.cudatoolkit;
          description = "Which CUDA package to use";
        };
      };
    };
    intel = {
      vaapiDriver = mkOption {
        type = types.enum [
          "iHD"
          "i965"
        ];
        default = "iHD";
        description = "Which vaapi driver to use";
      };
      openCL = mkEnableOption "Enable OpenCL Support";
    };
    amd = {
      vulkanDriver = mkOption {
        type = types.enum [
          "radv"
          "amdvlk"
        ];
        default = "radv";
        description = "Which vulkan driver to use";
      };
      openCL = {
        enable = mkEnableOption "Enable OpenCL Support";
        backend = mkOption {
          type = types.enum [
            "rusticl"
            "rocm"
          ];
          default = "rusticl";
          description = "Which OpenCL implementation to use";
        };
      };
    };
  };

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
              # nvidia-specific environment variables
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
