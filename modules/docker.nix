{ pkgs, ... }:

{
    # Enable Docker with enhanced security
    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        autoPrune = {
            enable = true;
            dates = "weekly";
        };
        daemon.settings = {
            log-driver = "json-file";
            log-opts = {
                max-size = "10m";
                max-file = "3";
            };
            # Basic security settings
            "no-new-privileges" = true;
            # Resource limits
            "default-ulimits" = {
                "memlock" = { "Hard" = 67108864; "Name" = "memlock"; "Soft" = 67108864; };
                "nofile" = { "Hard" = 1024; "Name" = "nofile"; "Soft" = 1024; };
            };
            # Disable experimental features in production
            "experimental" = false;
        };
    };

    # Open common ports for server services
    networking.firewall = {
        allowedTCPPorts = [ 
            3000  # Grafana
            9090  # Prometheus
            5432  # PostgreSQL
            6379  # Redis
            8080  # Common web services
            3100  # Loki
        ];
    };

    # Systemd service configuration for Docker
    systemd.services.docker.serviceConfig = {
        # Resource limits
        LimitNOFILE = "1048576";
        LimitNPROC = "1048576";
        LimitCORE = "infinity";
        TasksMax = "infinity";
        
        # Restart policy
        Restart = "on-failure";
        RestartSec = "5s";
    };
} 