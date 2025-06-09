{ lib, pkgs, ... }:
{
    imports = [
        ./modules/cursor.nix
        ./modules/obsidian.nix
    ];
    
    home.username = "berkay";
    home.homeDirectory = "/home/berkay";

    home.stateVersion = "24.11";

    nixpkgs.config.allowUnfree = true;

    home.packages = with pkgs; [
        alacritty
        dig
        nmap
        whois
        usbutils
        pciutils
        vlc
        nixpkgs-fmt
        nil
        gnupg
        htop
        jq
        openssl
        ripgrep
        meld
        tokei
        tree
        zellij
        neofetch
        google-chrome
        libreoffice-fresh
    ];

    home.sessionVariables = { };

    programs.alacritty = {
        enable = true;
        settings = {
            window = {
                dynamic_padding = true;
            };
        };
    };

    programs.bash = {
        enable = true;
        bashrcExtra = ''
        # Always open terminal in zellij session
        eval "$(zellij setup --generate-auto-start bash)"
        # Needed to use yubkiey for SSH key
        export GPG_TTY="$(tty)"
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        '';
    };

    programs.direnv = {
        enable = true;
    };

    services.gpg-agent = {
        enable = true;
        enableScDaemon = true;
        enableSshSupport = true;
        defaultCacheTtl = 60;
        maxCacheTtl = 120;
        pinentry.package = pkgs.pinentry-gnome3;
    };

    programs.git = {
        enable = true;
        userName = "Berkay";
        userEmail = "berkay.bayar21@outlook.com";
        extraConfig = {
            core = {
                editor = "hx";
                compression = 9;
            };
            init = {
                defaultBranch = "main";
            };
            pull = {
                rebase = true;
            };
            push = {
                autoSetupRemote = true;
            };
        };
    };

    programs.helix = {
        enable = true;
    };

    programs.zellij = {
        enable = true;
        settings = {
            ui = {
                pane_frames = {
                    hide_session_name = true;
                };
            };
        };
    };

    dconf.settings = {
        "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            cursor-theme ="Adwaita";
            show-battery-percentage = true;
        };
        "org/gnome/desktop/screensaver" = {
            lock-enabled = true;
        };
        "org/gnome/desktop/session" = {
            idle-delay = lib.hm.gvariant.mkUint32 900;
        };
        "org/gnome/desktop/notifications" = {
            show-in-lock-screen = false;
        };
        "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-ac-timeout = 900;
            sleep-inactive-battery-type = "nothing";
            sleep-inactive-battery-timeout = 900;
        };
        "org/gnome/shell" = {
            enabled-extensions = [
                "appindicatorsupport@rgcjonas.gmail.com"
                "dash-to-dock@micxgx.gmail.com"
                "blur-my-shell@aunetx"
                "Vitals@CoreCoding.com"
            ];
            favorite-apps = [
                "Alacritty.desktop"
                "google-chrome.desktop"
                "cursor.desktop"
                "obsidian.desktop"
                "rust-rover.desktop"
                "webstorm.desktop"
                "datagrip.desktop"
                "android-studio.desktop"
            ];
        };
        "org/gnome/shell/extensions/dash-to-dock" = {
            apply-custom-theme = true;
        };
        "org/gnome/system/location" = {
            enabled = false;
        };
    };
}
