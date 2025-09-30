{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.user.core = {
    name = mkOption {
      type = types.str;
      default = "user";
      description = "Login name for the user";
    };
    fullName = mkOption {
      type = types.str;
      default = "System User";
      description = "Display name for the user";
    };
    shell = mkOption {
      type = types.enum [
        "zsh"
        "bash"
        "dash"
        "fish"
      ];
      default = "zsh";
      description = "Which shell should the user use";
    };
  };

  config = {
    users.users.${config.lamentos.user.core.name} = {
      description = config.lamentos.user.core.fullName;
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "systemd-journal"
        "input"
      ];
      shell = pkgs.${config.lamentos.user.core.shell};
    };
    programs.${config.lamentos.user.core.shell}.enable = true;
    home-manager.users.${config.lamentos.user.core.name} = {
      home.username = config.lamentos.user.core.name;
      home.homeDirectory = "/home/${config.lamentos.user.core.name}";
      programs.${config.lamentos.user.core.shell}.enable = true;
      home.shell.enableShellIntegration = true;
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
  };
}
