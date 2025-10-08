{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options.lamentos.desktop.plasma6 = {
    enable = mkEnableOption "Enable the plasma6 Desktop Environment";
  };
  config = mkIf config.lamentos.desktop.plasma6.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
      xdgOpenUsePortal = true;
    };

    services = {
      dbus.enable = true;
      xserver.enable = true;
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    hardware.graphics.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.defaultSession = "plasma";

    # Additional KDE applications for "it just works" experience
    environment.systemPackages = with pkgs; [
      kdePackages.qtstyleplugin-kvantum # Work around for not finding kvantum?
      kdePackages.kcalc # Calculator
      kdePackages.filelight # Disk usage analyzer
      haruna # Video player
      kdePackages.discover # Software center
      kdePackages.partitionmanager # Disk partitioning
    ];
  };
}
