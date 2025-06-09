{ pkgs, lib, config, ... }:

{
    imports = [
        ./docker.nix
        ./sops.nix
        ./monitoring.nix
        ./secrets-setup.nix
    ];

    # Create server group
    users.groups.server = {};

    # Create server user
    users.users.server = {
        isNormalUser = true;
        description = "Server";
        group = "server";
        extraGroups = [ "docker" "wheel" ];
        shell = pkgs.bash;
    };

    # OpenSnitch rules for Docker and server services
    services.opensnitch.rules = {
      rule-200-docker = {
        name = "Allow Docker daemon";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          operand = "process.path";
          sensitive = false;
          data = "${lib.getBin pkgs.docker}/bin/dockerd";
        };
      };
      rule-200-docker-proxy = {
        name = "Allow Docker proxy";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          operand = "process.path";
          sensitive = false;
          data = "${lib.getBin pkgs.docker}/bin/docker-proxy";
        };
      };
      rule-200-containerd = {
        name = "Allow containerd";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          operand = "process.path";
          sensitive = false;
          data = "${lib.getBin pkgs.containerd}/bin/containerd";
        };
      };
      rule-200-docker-compose = {
        name = "Allow docker-compose";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          operand = "process.path";
          sensitive = false;
          data = "${lib.getBin pkgs.docker-compose}/bin/docker-compose";
        };
      };
      # Allow Docker network bridge traffic
      rule-200-docker-network = {
        name = "Allow Docker network bridge";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "network";
          operand = "dest.network";
          data = "172.16.0.0/12";
        };
      };
    };

    # Home manager for server user
    home-manager.users.server = {
        home.username = "server";
        home.homeDirectory = "/home/server";
        home.stateVersion = "24.11";

        home.packages = with pkgs; [
            btop
            docker-compose
            systemctl-tui
            age
            sops
        ];

        # Configure sops for the server user
        programs.bash = {
            enable = true;
            bashrcExtra = ''
            # Server user bash configuration
            export PATH="$PATH:/home/server/scripts"
            export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
            
            # Simple aliases
            alias start="server start"
            alias stop="server stop"
            alias restart="server restart"
            alias status="server status"
            alias logs="server logs"
            '';
        };

        # Remove all the clutter - keep only essential automated commands
        programs.git = {
            enable = true;
            userName = "Server";
            userEmail = "server@localhost";
            extraConfig = {
                core = {
                    editor = "nano";
                };
                init = {
                    defaultBranch = "main";
                };
            };
        };

        # Essential server management scripts only
        home.file."scripts/server".executable = true;
        home.file."scripts/server".text = ''
          #!/usr/bin/env bash
          
          # Clean up old scripts - NixOS will recreate configured ones
          cleanup_old_scripts() {
            if [ -d "$HOME/scripts" ]; then
              echo "🧹 Cleaning old scripts directory..."
              find "$HOME/scripts" -type f -not -name "server" -delete 2>/dev/null || true
            fi
          }
          
          # Run cleanup when called with any parameter
          if [ "$1" != "" ]; then
            cleanup_old_scripts
          fi
          
          case "$1" in
            start)
              echo "🚀 Starting server stack..."
              
              # Check if SOPS secrets exist (they should be files, not directories)
              if [ -f /run/secrets/server/postgres_password ] && [ -s /run/secrets/server/postgres_password ]; then
                echo "✅ Using SOPS-managed secrets"
              else
                echo "⚠️  SOPS secrets not found, checking if we need to rebuild..."
                
                # Find the actual NixOS configuration directory
                CONFIG_DIR=""
                for dir in /etc/nixos /home/berkay/Documents/nixos /home/*/nixos; do
                  if sudo test -f "$dir/secrets/secrets.yaml"; then
                    CONFIG_DIR="$dir"
                    break
                  fi
                done
                
                # Check if secrets.yaml is encrypted
                if [ -n "$CONFIG_DIR" ] && sudo head -1 "$CONFIG_DIR/secrets/secrets.yaml" | grep -q "sops:"; then
                  echo "❌ Secrets are encrypted but not deployed. Run: sudo nixos-rebuild switch"
                  exit 1
                elif [ -n "$CONFIG_DIR" ]; then
                  echo "❌ Secrets exist but not encrypted. Run: sudo nixos-rebuild switch"
                  exit 1
                else
                  echo "❌ No secrets configuration found!"
                  exit 1
                fi
              fi
              
              cd /home/server/docker
              docker-compose -f database.yml up -d
              sleep 5
              docker-compose -f monitoring.yml up -d
              sleep 10
              
              echo "✅ Server stack started!"
              echo "📊 Grafana: http://localhost:3000 (admin/[from secrets])"
              echo "📈 Prometheus: http://localhost:9090"
              echo "🐳 cAdvisor: http://localhost:8081"
              echo "🗄️  PostgreSQL: localhost:5432 (serveruser/[from secrets])"
              ;;
              
            stop)
              echo "🛑 Stopping server stack..."
              cd /home/server/docker
              docker-compose -f monitoring.yml down
              docker-compose -f database.yml down
              echo "✅ Server stack stopped!"
              ;;
              
            restart)
              $0 stop
              sleep 2
              $0 start
              ;;
              
            status)
              echo "📊 Server Status"
              echo "================"
              docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(grafana|prometheus|loki|postgres|redis|cadvisor|NAMES)"
              echo ""
              
              # Quick health check
              for service in "Grafana:3000" "Prometheus:9090" "Loki:3100" "cAdvisor:8081"; do
                name=$(echo $service | cut -d: -f1)
                port=$(echo $service | cut -d: -f2)
                if curl -s http://localhost:$port > /dev/null 2>&1; then
                  echo "✅ $name"
                else
                  echo "❌ $name"
                fi
              done
              ;;
              
            logs)
              if [ -z "$2" ]; then
                echo "Usage: server logs <container_name>"
                echo "Available: grafana, prometheus, loki, postgres, redis, cadvisor"
                exit 1
              fi
              docker logs -f "$2"
              ;;
              
            *)
              echo "🖥️  Server Management"
              echo "==================="
              echo "server start    - Start all services"
              echo "server stop     - Stop all services"  
              echo "server restart  - Restart all services"
              echo "server status   - Show status"
              echo "server logs <name> - Follow container logs"
              ;;
          esac
        '';

        home.file."scripts/setup-grafana".executable = true;
        home.file."scripts/setup-grafana".text = ''
          #!/usr/bin/env bash
          echo "🎨 Setting up Grafana dashboards..."
          
          # Wait for Grafana
          timeout 30 bash -c 'until curl -s http://localhost:3000/api/health > /dev/null; do sleep 2; done'
          
          echo "📊 Go to: http://localhost:3000"
          echo "🔑 Login: admin / admin123"
          echo "📊 Import these dashboard IDs:"
          echo "   • 1860 - Node Exporter Full"
          echo "   • 193 - Docker Container Monitoring (cAdvisor required)"
          echo "   • 13639 - Loki Dashboard"
          echo ""
          echo "🐳 cAdvisor is running at: http://localhost:8081"
          echo "   Direct access to container metrics and web UI"
        '';

        # Create server directories and secure compose files
        home.file."docker/monitoring.yml".text = ''
          services:
            grafana:
              image: grafana/grafana:latest
              container_name: grafana
              ports:
                - "3000:3000"
              environment:
                - GF_SECURITY_ADMIN_USER=admin
                - GF_SECURITY_ADMIN_PASSWORD__FILE=/run/secrets/grafana_admin_password
                - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
                # - GF_PATHS_PROVISIONING=/etc/grafana/provisioning # This will litter so better comment out
              volumes:
                - grafana_data:/var/lib/grafana
                # - ./grafana/datasources.yml:/etc/grafana/provisioning/datasources/datasources.yml:ro # This will litter so better comment out
                - /run/secrets/server/grafana_admin_password:/run/secrets/grafana_admin_password:ro
              restart: unless-stopped
              security_opt:
                - no-new-privileges:true
              user: "root"
              networks:
                - monitoring
          
            prometheus:
              image: prom/prometheus:latest
              container_name: prometheus
              ports:
                - "9090:9090"
              volumes:
                - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
                - prometheus_data:/prometheus
              restart: unless-stopped
              security_opt:
                - no-new-privileges:true
              user: "65534"
              command:
                - '--config.file=/etc/prometheus/prometheus.yml'
                - '--storage.tsdb.path=/prometheus'
                - '--web.console.libraries=/etc/prometheus/console_libraries'
                - '--web.console.templates=/etc/prometheus/consoles'
                - '--storage.tsdb.retention.time=15d'
                - '--web.enable-lifecycle'
                - '--web.enable-admin-api'
              networks:
                - monitoring
          
            loki:
              image: grafana/loki:3.5.1
              container_name: loki
              ports:
                - "3100:3100"
              volumes:
                - loki_data:/loki
                - ./loki/loki-config.yaml:/etc/loki/local-config.yaml:ro
              restart: unless-stopped
              security_opt:
                - no-new-privileges:true
              user: "10001"
              command: -config.file=/etc/loki/local-config.yaml
              networks:
                - monitoring

            cadvisor:
              image: gcr.io/cadvisor/cadvisor:v0.50.0
              container_name: cadvisor
              ports:
                - "8081:8080"
              volumes:
                - /:/rootfs:ro
                - /var/run:/var/run:ro
                - /sys:/sys:ro
                - /var/lib/docker/:/var/lib/docker:ro
                - /dev/disk/:/dev/disk:ro
              restart: unless-stopped
              security_opt:
                - no-new-privileges:true
              privileged: true
              devices:
                - /dev/kmsg
              networks:
                - monitoring
          
          volumes:
            grafana_data:
            prometheus_data:
            loki_data:
          
          networks:
            monitoring:
              driver: bridge
        '';

        home.file."docker/database.yml".text = ''
          services:
            postgres:
              image: postgres:15
              container_name: postgres
              ports:
                - "5432:5432"
              environment:
                - POSTGRES_DB=serverdb
                - POSTGRES_USER=serveruser
                - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
                - POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256
                - POSTGRES_HOST_AUTH_METHOD=scram-sha-256
              volumes:
                - postgres_data:/var/lib/postgresql/data
                - /run/secrets/server/postgres_password:/run/secrets/postgres_password:ro
              restart: unless-stopped
              security_opt:
                - no-new-privileges:true
              shm_size: 256mb
              networks:
                - database
          
            redis:
              image: redis:7-alpine
              container_name: redis
              ports:
                - "6379:6379"
              environment:
                - REDIS_PASSWORD_FILE=/run/secrets/redis_password
              volumes:
                - redis_data:/data
                - /run/secrets/server/redis_password:/run/secrets/redis_password:ro
              restart: unless-stopped
              security_opt:
                - no-new-privileges:true
              command: ["sh", "-c", "redis-server --requirepass $$(cat /run/secrets/redis_password)"]
              networks:
                - database
          
          volumes:
            postgres_data:
            redis_data:
          
          networks:
            database:
              driver: bridge
        '';

        home.file."docker/prometheus/prometheus.yml".text = ''
          global:
            scrape_interval: 15s
            evaluation_interval: 15s
          
          scrape_configs:
            - job_name: 'prometheus'
              static_configs:
                - targets: ['localhost:9090']
            
            - job_name: 'node-exporter'
              static_configs:
                - targets: ['172.17.0.1:9100']
            
            - job_name: 'systemd-exporter'
              static_configs:
                - targets: ['172.17.0.1:9558']

            - job_name: 'cadvisor'
              static_configs:
                - targets: ['cadvisor:8080']
              scrape_interval: 30s
              metrics_path: /metrics
        '';

        home.file."docker/loki/loki-config.yaml".text = ''
          auth_enabled: false
          
          server:
            http_listen_port: 3100
          
          common:
            path_prefix: /loki
            storage:
              filesystem:
                chunks_directory: /loki/chunks
                rules_directory: /loki/rules
            replication_factor: 1
            ring:
              instance_addr: 127.0.0.1
              kvstore:
                store: inmemory
          
          schema_config:
            configs:
              - from: 2020-10-24
                store: tsdb
                object_store: filesystem
                schema: v13
                index:
                  prefix: index_
                  period: 24h
          
          limits_config:
            allow_structured_metadata: false
            reject_old_samples: true
            reject_old_samples_max_age: 168h
            ingestion_rate_mb: 16
            ingestion_burst_size_mb: 32
        '';

        home.file."scripts/fix-containers".executable = true;
        home.file."scripts/fix-containers".text = ''
          #!/usr/bin/env bash
          echo "=== Fixing container issues ==="
          
          # Stop all containers first
          echo "Stopping containers..."
          cd /home/server/docker
          docker-compose -f monitoring.yml down 2>/dev/null || true
          docker-compose -f database.yml down 2>/dev/null || true
          
          # Check if secrets exist and are accessible
          echo "Checking secrets..."
          if [ -f /run/secrets/server/postgres_password ] && [ -s /run/secrets/server/postgres_password ]; then
            echo "✅ SOPS secrets found and accessible"
          else
            echo "❌ SOPS secrets not properly deployed!"
            echo "Current state:"
            ls -la /run/secrets/server/ 2>/dev/null || echo "  No SOPS secrets found"
            echo ""
            echo "To fix this:"
            echo "1. Ensure your NixOS config has encrypted secrets:"
            CONFIG_DIR=""
            for dir in /etc/nixos /home/berkay/Documents/nixos /home/*/nixos; do
              if sudo test -f "$dir/secrets/secrets.yaml"; then
                CONFIG_DIR="$dir"
                break
              fi
            done
            if [ -n "$CONFIG_DIR" ]; then
              echo "   Found config at: $CONFIG_DIR"
              echo "   Check encryption: sudo head -1 $CONFIG_DIR/secrets/secrets.yaml"
            else
              echo "   No secrets.yaml found in standard locations"
            fi
            echo "2. Rebuild NixOS: sudo nixos-rebuild switch"
            echo "3. Check secrets after rebuild: ls -la /run/secrets/server/"
            exit 1
          fi
          
          # Remove old containers and volumes if they exist
          echo "Cleaning up old containers..."
          docker container rm -f postgres loki grafana prometheus redis 2>/dev/null || true
          
          # Recreate containers with proper configuration
          echo "Starting database stack..."
          cd /home/server/docker
          docker-compose -f database.yml up -d
          
          echo "Waiting for database to initialize..."
          sleep 10
          
          echo "Starting monitoring stack..."
          docker-compose -f monitoring.yml up -d
          
          echo "Waiting for services to start..."
          sleep 15
          
          echo "=== Container Status ==="
          docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
          
          echo ""
          echo "=== Service Health Check ==="
          
          # Check PostgreSQL
          if docker exec postgres pg_isready -U serveruser -d serverdb > /dev/null 2>&1; then
            echo "PostgreSQL: ✓ Ready"
          else
            echo "PostgreSQL: ✗ Not ready"
          fi
          
          # Check Redis
          if docker exec redis redis-cli ping > /dev/null 2>&1; then
            echo "Redis: ✓ Ready"
          else
            echo "Redis: ✗ Not ready"
          fi
          
          # Check Prometheus
          if curl -s http://localhost:9090/-/ready > /dev/null 2>&1; then
            echo "Prometheus: ✓ Ready"
          else
            echo "Prometheus: ✗ Not ready"
          fi
          
          # Check Grafana
          if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
            echo "Grafana: ✓ Ready"
          else
            echo "Grafana: ✗ Not ready"
          fi
          
          # Check Loki
          if curl -s http://localhost:3100/ready > /dev/null 2>&1; then
            echo "Loki: ✓ Ready"
          else
            echo "Loki: ✗ Not ready"
          fi
          
          # Check cAdvisor
          if curl -s http://localhost:8081/healthz > /dev/null 2>&1; then
            echo "cAdvisor: ✓ Ready"
          else
            echo "cAdvisor: ✗ Not ready"
          fi
          
          echo ""
          echo "If any services are not ready, check logs with:"
          echo "docker logs <container_name>"
        '';

        home.file."scripts/check-secrets".executable = true;
        home.file."scripts/check-secrets".text = ''
          #!/usr/bin/env bash
          echo "🔍 Checking SOPS secrets..."
          
          # Check if secrets exist where SOPS puts them
          for secret in postgres_password grafana_admin_password redis_password; do
            secret_path="/run/secrets/server/$secret"
            if [ -f "$secret_path" ] && [ -s "$secret_path" ]; then
              echo "✅ $secret: Ready"
            else
              echo "❌ $secret: Missing or empty"
            fi
          done
          
          echo ""
          echo "If secrets are missing, run: sudo nixos-rebuild switch"
        '';

        # Add Grafana datasources configuration
        home.file."docker/grafana/datasources.yml".text = ''
          apiVersion: 1
          
          datasources:
            - name: Prometheus
              type: prometheus
              access: proxy
              url: http://prometheus:9090
              isDefault: true
              editable: true
              
            - name: Loki
              type: loki
              access: proxy
              url: http://loki:3100
              editable: true
        '';

        # Add Redis configuration
        home.file."docker/redis/redis.conf".text = ''
          # Redis configuration
          # Use requirepass instead of requirepass_file (which doesn't exist)
          # requirepass redispass123
          save 900 1
          save 300 10
          save 60 10000
          stop-writes-on-bgsave-error yes
          rdbcompression yes
          rdbchecksum yes
          dbfilename dump.rdb
          dir /data
          maxmemory-policy allkeys-lru
          tcp-keepalive 300
          timeout 0
        '';
    };
}