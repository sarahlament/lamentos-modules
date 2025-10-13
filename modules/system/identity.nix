{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types mkDefault mkIf;
  cfg = config.lamentos.system.identity;
in {
  options.lamentos.system.identity = {
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
      description = "Should we allow 'unfree' software";
    };
    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "Hostname for the system";
    };
    enableZswap = mkOption {
      type = types.bool;
      default = true;
      description = "Use ZSwap instead of normal swap";
    };
  };

  config = {
    system.stateVersion = cfg.stateVersion;

    nixpkgs.hostPlatform = cfg.systemType;
    nixpkgs.config.allowUnfree = cfg.allowUnfree;
    networking.hostName = cfg.hostName;

    networking.networkmanager.enable = mkDefault true;

    boot.kernelParams = mkIf cfg.enableZswap [
      "zswap.enabled=1"
      "zswap.compressor=lz4"
      "zswap.mox_pool_percent=20"
      "zswap.shrinker_enabled=1"
    ];
  };
}
