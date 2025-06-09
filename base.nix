{ pkgs, ... }:

{
    imports = 
    [
        <home-manager/nixos>
        <sops-nix/modules/sops>
        ./modules/gnome.nix
        ./modules/antivirus.nix
        ./modules/rust.nix
        ./modules/opensnitch.nix
# FIXME: does not work.         ./modules/davinci-resolve.nix
# FIXME: does not work.        ./modules/teams.nix
        ./modules/jetbrains.nix
        ./modules/android-studio.nix
    ];

    boot.loader.systemd-boot.configurationLimit = 20;

    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Istanbul";

    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
        LC_ADDRESS = "tr_TR.UTF-8";
        LC_IDENTIFICATION = "tr_TR.UTF-8";
        LC_MEASUREMENT = "tr_TR.UTF-8";
        LC_MONETARY = "tr_TR.UTF-8";
        LC_NAME = "tr_TR.UTF-8";
        LC_NUMERIC = "tr_TR.UTF-8";
        LC_PAPER = "tr_TR.UTF-8";
        LC_TELEPHONE = "tr_TR.UTF-8";
        LC_TIME = "tr_TR.UTF-8";
    };

    services.xserver.enable = true;

    services.xserver.xkb = {
        layout = "us";
        variant = "";
    };

    services.printing.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
    };

    hardware.bluetooth.powerOnBoot = false;

    users.users.berkay = {
        isNormalUser = true;
        description = "Berkay";
        extraGroups = [ "networkmanager" "wheel" "opensnitch" ]; 
    };

    home-manager.users.berkay = import ./home.nix;

    nixpkgs.config.allowUnfree = true;

    system.autoUpgrade = {
        enable = true;
        dates = "daily";
        operation = "boot";
    };

    nix = {
        daemonCPUSchedPolicy = "idle";
        daemonIOSchedClass = "idle";
    };

    services.udev.packages = [ pkgs.yubikey-personalization ];

    environment.systemPackages = with pkgs; [
        helix
        home-manager
    ];

    services.auto-cpufreq.enable = true;
    services.auto-cpufreq.settings = {
        battery = {
            governor = "powersave";
            turbo = "never";
        };
        charger = {
            governor = "performance";
            turbo = "auto";
        };
    };

    services.power-profiles-daemon.enable = false;

    system.stateVersion = "24.11";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
