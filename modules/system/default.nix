{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
  cfg = config.lamentos.system.identity;
in {
  imports = [
    ./identity.nix # System Identity settings
    ./theming # System level theming
  ];

  config = {
    system.stateVersion = cfg.stateVersion;

    nixpkgs.hostPlatform = cfg.systemType;
    nixpkgs.config.allowUnfree = cfg.allowUnfree;
    networking.hostName = cfg.hostName;

    networking.networkmanager.enable = mkDefault true;
  };
}
