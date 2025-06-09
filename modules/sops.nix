{ pkgs, lib, ... }:

{
  # Enable sops-nix for secrets management
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    
    # Age key configuration
    age = {
      keyFile = "/home/server/.config/sops/age/keys.txt";
      sshKeyPaths = [ ];
    };
    
    # Simple secret configuration - SOPS will handle everything
    secrets = {
      "server/postgres_password" = {
        owner = "server";
        group = "docker";
        mode = "0444";
      };
      "server/grafana_admin_password" = {
        owner = "server";
        group = "docker";
        mode = "0444";
      };
      "server/redis_password" = {
        owner = "server";
        group = "docker";
        mode = "0444";
      };
    };
  };

  # Required packages for managing secrets
  environment.systemPackages = with pkgs; [
    sops
    age
  ];
} 