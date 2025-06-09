{ pkgs, ... }:

{
  # System monitoring with Prometheus
  services.prometheus.exporters = {
    node = {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "systemd"
        "processes"
        "interrupts"
        "buddyinfo"
        "meminfo_numa"
      ];
    };
    
    # Monitor systemd services
    systemd = {
      enable = true;
      port = 9558;
    };
  };

  # Log monitoring
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [
        {
          url = "http://localhost:3100/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "systemd-journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "berkay-laptop";
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };

  # System resource monitoring
  systemd.services.disk-usage-monitor = {
    description = "Monitor disk usage and alert on high usage";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "disk-monitor" ''
        #!/bin/bash
        USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ $USAGE -gt 85 ]; then
          echo "WARNING: Root filesystem is $USAGE% full" | systemd-cat -t disk-monitor -p warning
        fi
      '';
    };
  };

  systemd.timers.disk-usage-monitor = {
    description = "Run disk usage monitor every hour";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Unit = "disk-usage-monitor.service";
    };
  };

  # Open monitoring ports in firewall
  networking.firewall.allowedTCPPorts = [ 
    9100  # Node exporter
    9558  # Systemd exporter
    3100  # Loki (if used)
  ];

  # OpenSnitch rules for monitoring
  services.opensnitch.rules = {
    rule-200-prometheus-exporters = {
      name = "Allow Prometheus exporters";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = [
          {
            type = "regexp";
            operand = "process.path";
            sensitive = false;
            data = "^.*prometheus.*exporter.*$";
          }
          {
            type = "simple";
            operand = "dest.ip";
            sensitive = false;
            data = "127.0.0.1";
          }
        ];
      };
    };
  };
} 