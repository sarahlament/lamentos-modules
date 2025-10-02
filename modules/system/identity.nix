{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.system.identity = {
    stateVersion = mkOption {
      type = types.str;
      default = "25.11";
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
  };

  config = mkMerge [
    {
      system.stateVersion = config.lamentos.system.identity.stateVersion;

      nixpkgs.hostPlatform = config.lamentos.system.identity.systemType;
      nixpkgs.config.allowUnfree = config.lamentos.system.identity.allowUnfree;
      networking.hostName = config.lamentos.system.identity.hostName;
    }
  ];
}
