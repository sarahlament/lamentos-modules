{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
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
}
