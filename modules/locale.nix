{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos = {
    locale = {
      timeZone = mkOption {
        type = types.str;
        default = "UTC";
        description = "The timezone for the system";
        example = "America/Chicago";
      };
      defaultLocale = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
        description = "The default locale for the system";
        example = "en_US.UTF-8";
      };
      extraLocaleSettings = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Additional locale settings";
        example = {
          LC_ADDRESS = "en_US.UTF-8";
          LC_IDENTIFICATION = "en_US.UTF-8";
          LC_MEASUREMENT = "en_US.UTF-8";
          LC_MONETARY = "en_US.UTF-8";
          LC_NAME = "en_US.UTF-8";
          LC_NUMERIC = "en_US.UTF-8";
          LC_PAPER = "en_US.UTF-8";
          LC_TELEPHONE = "en_US.UTF-8";
          LC_TIME = "en_US.UTF-8";
        };
      };
    };
    fonts = {
      enableDefaultFonts = mkOption {
        type = types.bool;
        default = true;
        description = "Enable a sensible set of default fonts";
      };
      packages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Additional font packages to install";
        example = literalExpression ''
          with pkgs; [
            dejavu_fonts
            liberation_ttf
          ]
        '';
      };
    };
  };

  config = mkMerge [
    {
      time.timeZone = config.lamentos.locale.timeZone;
      i18n.defaultLocale = config.lamentos.locale.defaultLocale;
      i18n.extraLocaleSettings = config.lamentos.locale.extraLocaleSettings;
    }
    (mkIf (config.lamentos.fonts.enableDefaultFonts == true) {
      fonts.packages = with pkgs; [
        # Icon fonts
        font-awesome

        # Programming fonts
        nerd-fonts.jetbrains-mono
        fira-code

        # UI/System fonts
        inter
        roboto

        # Serif fonts
        source-serif-pro

        # System compatibility fonts
        liberation_ttf
        dejavu_fonts

        # Unicode and emoji support
        noto-fonts-cjk-sans
        noto-fonts-emoji
        noto-fonts-extra
      ] ++ config.lamentos.fonts.packages;
    })
    (mkIf (config.lamentos.fonts.enableDefaultFonts == false) {
      fonts.packages = config.lamentos.fonts.packages;
    })
  ];
}