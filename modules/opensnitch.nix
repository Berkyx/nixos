{ pkgs, lib, ... }:
{
  environment.systemPackages = [
    pkgs.opensnitch-ui
  ];

  # Set start up applications with user-specific socket path
  # shitty version of this https://github.com/nix-community/home-manager/issues/3447#issuecomment-1328294558
  environment.etc."xdg/autostart/opensnitch_ui.desktop".text = ''
    [Desktop Entry]
    Name=OpenSnitch UI
    Comment=Application firewall UI
    Exec=${pkgs.opensnitch-ui}/bin/opensnitch-ui --socket unix:///run/user/1000/opensnitch/osui.sock
    Icon=opensnitch-ui
    Type=Application
    Categories=Network;Security;
    StartupNotify=false
    X-GNOME-Autostart-enabled=true
  '';

  # Create runtime directory for user sockets
  systemd.user.tmpfiles.rules = [
    "d /run/user/1000/opensnitch 0755 berkay berkay -"
  ];

  # A list of general rules needed no matter how the system is configured
  services.opensnitch = {
    enable = true;
    settings.DefaultAction = "deny";
    settings.Server = {
      Address = "unix:///run/user/1000/opensnitch/osui.sock";
      LogFile = "/var/log/opensnitchd.log";
    };
    rules = {
      rule-000-localhost = {
        name = "Allow all localhost";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "regexp";
          operand = "dest.ip";
          sensitive = false;
          data = "^(127\\.0\\.0\\.1|::1)$";
          list = [ ];
        };
      };
      rule-100-avahi-ipv4 = {
        name = "Allow avahi daemon IPv4";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "process.path";
              sensitive = false;
              data = "${lib.getBin pkgs.avahi}/bin/avahi-daemon";
            }
            {
              type = "network";
              operand = "dest.network";
              data = "224.0.0.0/24";
            }
          ];
        };
      };
      rule-100-avahi-ipv6 = {
        name = "Allow avahi daemon IPv6";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              operand = "process.path";
              sensitive = false;
              data = "${lib.getBin pkgs.avahi}/bin/avahi-daemon";
            }
            {
              type = "simple";
              operand = "dest.ip";
              data = "ff02::fb";
            }
          ];
        };
      };
      rule-100-ntp = {
        name = "Allow NTP";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              sensitive = false;
              operand = "process.path";
              data = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-timesyncd";
            }
            {
              type = "simple";
              operand = "dest.port";
              sensitive = false;
              data = "123";
            }
            {
              type = "simple";
              operand = "protocol";
              sensitive = false;
              data = "udp";
            }
          ];
        };
      };
      rule-100-nix-update = {
        name = "Allow Nix";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              sensitive = false;
              operand = "process.path";
              data = "${lib.getBin pkgs.nix}/bin/nix";
            }
            {
              type = "regexp";
              operand = "dest.host";
              sensitive = false;
              data = "^(([a-z0-9|-]+\\.)*github\\.com|([a-z0-9|-]+\\.)*nixos\\.org)$";
            }
          ];
        };
      };
      rule-100-NetworkManager = {
        name = "Allow NetworkManager";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              sensitive = false;
              operand = "process.path";
              data = "${lib.getBin pkgs.networkmanager}/bin/NetworkManager";
            }
            {
              type = "simple";
              operand = "dest.port";
              sensitive = false;
              data = "67";
            }
            {
              type = "simple";
              operand = "protocol";
              sensitive = false;
              data = "udp";
            }
          ];
        };
      };
      rule-500-ssh-github = {
        name = "Allow SSH to github";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "list";
          operand = "list";
          list = [
            {
              type = "simple";
              sensitive = false;
              operand = "process.path";
              data = "${lib.getBin pkgs.openssh}/bin/ssh";
            }
            {
              type = "simple";
              operand = "dest.host";
              sensitive = false;
              data = "github.com";
            }
          ];
        };
      };
    };
  };
  
  # Fix systemd service to run with proper group and set socket permissions
  systemd.services.opensnitchd = {
    serviceConfig = {
      Group = "opensnitch";
      UMask = "0002";
      SupplementaryGroups = [ "opensnitch" ];
    };
    postStart = ''
      # Wait for the socket to be created and fix permissions
      for i in {1..10}; do
        if [ -S /run/user/1000/opensnitch/osui.sock ]; then
          ${pkgs.coreutils}/bin/chown berkay:opensnitch /run/user/1000/opensnitch/osui.sock
          ${pkgs.coreutils}/bin/chmod 0660 /run/user/1000/opensnitch/osui.sock
          echo "OpenSnitch socket permissions fixed"
          break
        fi
        sleep 1
      done
    '';
  };
  
  # Create the opensnitch group
  users.groups.opensnitch = {};
}