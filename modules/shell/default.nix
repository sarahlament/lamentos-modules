{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.lamentos.shell;
in {
  imports = [
    ./modernTools.nix # modern replacements for shell commands
  ];
  config = mkMerge [
    (mkIf (cfg.modernTools.enable) {
      home-manager.sharedModules = [
        {
          home.shellAliases = {
            c = "clear";
            cat = "bat";
            ls = "eza";
            la = "eza -a --grid ";
            lt = "eza --tree --level=1";
            ll = "eza -l --grid";
            lla = "eza -la --grid";
            ltt = "eza --tree";
            grep = "rg --color=auto";
          };
          programs = {
            bat.enable = true;
            eza = {
              enable = true;
              colors = "auto";
              icons = "auto";
              extraOptions = [
                "--group-directories-first"
                "--follow-symlinks"
                "--no-filesize"
                "--no-time"
                "--no-permissions"
                "--octal-permissions"
              ];
            };
            fd.enable = true;
            fzf.enable = true;
            ripgrep.enable = true;
            zoxide.enable = true;
          };
        }
      ];
    })
  ];
}
