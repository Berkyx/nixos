{ pkgs, lib, ... }:

{
  # Simple systemd service to ensure server user home directory exists
  systemd.services.ensure-server-home = {
    description = "Ensure server user home directory exists";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ensure-server-home" ''
        #!/bin/bash
        mkdir -p /home/server
        chown server:server /home/server
        echo "✅ Server home directory ready"
      '';
    };
  };
} 