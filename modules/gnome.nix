{ pkgs, lib, ... }:
{
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    environment.systemPackages = with pkgs.gnomeExtensions; [
        appindicator
        dash-to-dock
        vitals
        blur-my-shell
    ];

    environment.gnome.excludePackages = (with pkgs; [
        epiphany
        geary
        gnome-calendar
        gnome-characters
        gnome-clocks
        gnome-font-viewer
        gnome-keyring
        gnome-maps
        gnome-music
        gnome-remote-desktop
        gnome-photos
        gnome-terminal
        gnome-tour
        yelp
    ]);
    services.opensnitch.rules = {
        rule-500-gnome-calc = {
        name = "Block calculator from any network access";
        enabled = true;
        action = "deny";
        duration = "always";
        operator =
            {
            type = "simple";
            sensitive = false;
            operand = "process.path";
            data = "${lib.getBin pkgs.gnome-calculator}/bin/.gnome-calculator-wrapped";
            };
        };
    };
}