{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  imports = [
    ./core.nix # Core theming options
    ./settings.nix # Various option sets for stylix's theming
  ];

  config = mkMerge [
    (mkIf (config.lamentos.system.theming.enable) {
      stylix = {
        enable = true;

        fonts = {
          monospace = {
            package = config.lamentos.system.theming.fonts.monospace.package;
            name = config.lamentos.system.theming.fonts.monospace.name;
          };
          sansSerif = {
            package = config.lamentos.system.theming.fonts.sansSerif.package;
            name = config.lamentos.system.theming.fonts.sansSerif.name;
          };
          serif = {
            package = config.lamentos.system.theming.fonts.serif.package;
            name = config.lamentos.system.theming.fonts.serif.name;
          };
          sizes = mkDefault {
            applications = 14;
            desktop = 12;
          };
        };

        cursor = {
          package = config.lamentos.system.theming.cursor.package;
          name = config.lamentos.system.theming.cursor.name;
          size = config.lamentos.system.theming.cursor.size;
        };
      };
    })
    (mkIf (config.lamentos.system.theming.useCustomTheme) {
      stylix.base16Scheme = ./lamentos.yaml;

      # Override base0F-base17 - base16.nix only exposes base00-0E by default
      # Manually inject base24 extended colors until stylix handles them
      stylix.override = {
        base0F = "d8a8f0"; # REPURPOSED: neutral/metadata + delimiters/punctuation
        base10 = "98d898"; # STATUS: success/healthy
        base11 = "e0d088"; # STATUS: warning/attention
        base12 = "e88888"; # STATUS: error/critical
        base13 = "98c8e8"; # STATUS: info/special
        base14 = "c8a8f8"; # DOMAIN: active/focus
        base15 = "88e8e8"; # DOMAIN: time/duration
        base16 = "d0b080"; # DOMAIN: git+dev context
        base17 = "b0a8d8"; # DOMAIN: system/hardware info
      };
    })
    (mkIf (config.lamentos.system.theming.omp.enable) {
      home-manager.sharedModules = [
        {
          programs.oh-my-posh = {
            enable = true;
            settings = {
              "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
              # Theme palette using Base24 semantic colors
              palette = {
                active_focus = config.lib.stylix.colors.withHashtag.base14; # DOMAIN: active/focus
                system_info = config.lib.stylix.colors.withHashtag.base17; # DOMAIN: system/hardware info
                time_display = config.lib.stylix.colors.withHashtag.base15; # DOMAIN: time/duration
                dev_context = config.lib.stylix.colors.withHashtag.base16; # DOMAIN: git+dev context
                status_success = config.lib.stylix.colors.withHashtag.base10; # STATUS: success
                status_warning = config.lib.stylix.colors.withHashtag.base11; # STATUS: warning
                status_error = config.lib.stylix.colors.withHashtag.base12; # STATUS: error/critical
              };
              upgrade = {
                source = "cdn";
                interval = "168h";
                auto = false;
                notice = false;
              };
              transient_prompt = {
                foreground = "p:active_focus";
                template = "❯ ";
              };
              blocks = [
                {
                  type = "prompt";
                  alignment = "left";
                  segments = [
                    {
                      template = "{{.Icon}} ";
                      foreground = "p:system_info";
                      type = "os";
                      style = "plain";
                    }
                    {
                      template = "{{ .UserName }}@{{ .HostName }} ";
                      foreground = "p:active_focus";
                      type = "session";
                      style = "plain";
                    }
                    {
                      properties = {
                        home_icon = "~";
                        style = "full";
                      };
                      template = "{{ .Path }} ";
                      foreground = "p:active_focus";
                      type = "path";
                      style = "plain";
                    }
                    {
                      properties = {
                        fetch_status = true;
                        fetch_upstream_icon = true;
                      };
                      template = "{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{.UpstreamIcon }}{{ if .Staging.Changed }} <p:status_success> {{ .Staging.String }}</p:status_success>{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Working.Changed }} <p:status_warning> {{ .Working.String }}</p:status_warning>{{ end }} ";
                      foreground = "p:dev_context";
                      type = "git";
                      style = "plain";
                    }
                  ];
                  newline = true;
                }
                {
                  type = "prompt";
                  alignment = "left";
                  segments = [
                    {
                      type = "python";
                      style = "plain";
                      foreground = "p:dev_context";
                      template = " {{ .Venv }} ";
                    }
                    {
                      type = "node";
                      style = "plain";
                      foreground = "p:dev_context";
                      template = " {{ .Major }}.{{ .Minor }} ";
                    }
                    {
                      type = "docker";
                      style = "plain";
                      foreground = "p:dev_context";
                      template = " {{ .Context }} ";
                    }
                    {
                      type = "go";
                      style = "plain";
                      foreground = "p:dev_context";
                      template = " {{ .Major }}.{{ .Minor }} ";
                    }
                    {
                      type = "rust";
                      style = "plain";
                      foreground = "p:dev_context";
                      template = " {{ .Major }}.{{ .Minor }} ";
                    }
                  ];
                  newline = true;
                }
                {
                  type = "prompt";
                  alignment = "right";

                  segments = [
                    {
                      type = "sysinfo";
                      style = "plain";
                      foreground = "p:system_info";
                      template = "󰘚 {{ round .PhysicalPercentUsed .Precision }}% ";
                      properties = {
                        precision = 1;
                      };
                    }
                    {
                      type = "time";
                      style = "plain";
                      foreground = "p:time_display";
                      template = "󰅐 {{ .CurrentDate | date .Format }}";
                      properties = {
                        time_format = "15:04";
                      };
                    }
                  ];
                }
                {
                  type = "prompt";
                  alignment = "left";
                  segments = [
                    {
                      template = "❯ ";
                      foreground = "p:active_focus";
                      type = "text";
                      style = "plain";
                    }
                  ];
                }
                {
                  type = "rprompt";
                  segments = [
                    {
                      type = "executiontime";
                      style = "plain";
                      foreground = "p:time_display";
                      template = "{{ .FormattedMs }}";
                      properties = {
                        style = "roundrock";
                        threshold = 2000;
                      };
                    }
                    {
                      type = "status";
                      style = "plain";
                      foreground = "p:status_error";
                      template = " ✘ {{ .Code }}";
                      properties = {
                        always_enabled = false;
                      };
                    }
                  ];
                }
              ];
              version = 3;
              final_space = true;
            };
          };
        }
      ];
    })
  ];
}
