{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
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
}
