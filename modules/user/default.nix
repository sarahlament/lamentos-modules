{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./user.nix # Multi-user system configuration
  ];

  config = {
    # Create system users for each configured user
    users.users =
      mapAttrs (
        username: userConfig:
          mkIf userConfig.enable {
            description = userConfig.fullName;
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "systemd-journal"
              "input"
            ];
            shell = pkgs.${userConfig.shell};
          }
      )
      config.lamentos.user;

    # Enable required shell programs
    programs = mkMerge (
      mapAttrsToList (
        username: userConfig:
          mkIf userConfig.enable {
            ${userConfig.shell}.enable = true;
          }
      )
      config.lamentos.user
    );

    # Configure home-manager for each user
    home-manager.users =
      mapAttrs (
        username: userConfig:
          mkIf userConfig.enable {
            home.username = username;
            home.homeDirectory = "/home/${username}";
            programs.${userConfig.shell}.enable = true;
            home.shell.enableShellIntegration = true;
            home.stateVersion = config.lamentos.system.identity.stateVersion;
          }
      )
      config.lamentos.user;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    # This is in fact correct. sudoNoPasword defaults to false, which is what this needs to work correcrly, so we need the inverse of the option
    security.sudo.wheelNeedsPassword = !(config.lamentos.users.sudoNoPassword);
  };
}
