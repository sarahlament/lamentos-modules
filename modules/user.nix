{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  options.lamentos = {
    user = {
      name = mkOption {
        type = types.str;
        default = "user";
        description = "login name for the user";
      };
      fullName = mkOption {
        type = types.str;
        default = "System User";
        description = "display name for the user";
      };
      shell = mkOption {
        type = types.enum [
          "zsh"
          "bash"
          "dash"
          "fish"
        ];
        default = "zsh";
        description = "which shell should the user use";
      };
    };
    desktop = {
      xdgThings = mkOption {
        type = types.bool;
        default = true;
        description = "do we want to setup XDG things?";
      };
    };
  };

  config = mkMerge [
    {
      programs.${config.lamentos.user.shell}.enable = true;
      users.users.${config.lamentos.user.name} = {
        description = config.lamentos.user.fullName;
        isNormalUser = true;
        extraGroups = [
          "wheel"
          "systemd-journal"
        ];
        shell = pkgs.${config.lamentos.user.shell};
      };
      home-manager.users.${config.lamentos.user.name} = {
        home.username = config.lamentos.user.name;
        home.homeDirectory = "/home/${config.lamentos.user.name}";
        home.shell.enableShellIntegration = true;

        programs.${config.lamentos.user.shell}.enable = true;
      };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
    (mkIf (config.lamentos.desktop.xdgThings == true) {
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
        ];
      };
      home-manager.users.${config.lamentos.user.name} = {
        home.preferXdgDirectories = true;
        xdg = {
          enable = true;
          portal = {
            enable = true;
            extraPortals = with pkgs; [
              xdg-desktop-portal-hyprland
              xdg-desktop-portal-gtk
            ];
            configPackages = [pkgs.hyprland];
          };
          userDirs.enable = true;
          userDirs.createDirectories = true;
          mime.enable = true;
          mimeApps.enable = true;
        };
      };
    })
  ];
}
