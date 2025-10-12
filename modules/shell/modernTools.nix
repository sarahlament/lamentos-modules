{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;
  cfg = config.lamentos.shell;
in {
  options.lamentos.shell.modernTools = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Should we use modern replacement tools written in rust";
    };
    useRustSudo = mkOption {
      type = types.bool;
      default = false;
      description = "Should we use the rust sudo package? (Seperated for security reasons)";
    };
  };
  config = {
    home-manager.sharedModules = mkIf (cfg.modernTools.enable) [
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
    security.sudo-rs.enable = cfg.modernTools.useRustSudo;
  };
}
