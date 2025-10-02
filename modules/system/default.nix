{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./identity.nix # System Identity settings
    ./theming # System level theming
  ];

  config = {
    system.stateVersion = config.lamentos.system.identity.stateVersion;

    nixpkgs.hostPlatform = config.lamentos.system.identity.systemType;
    nixpkgs.config.allowUnfree = config.lamentos.system.identity.allowUnfree;
    networking.hostName = config.lamentos.system.identity.hostName;

    networking.networkmanager.enable = mkDefault true;
  };
}
