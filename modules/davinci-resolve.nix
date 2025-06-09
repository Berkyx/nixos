{ pkgs, lib, ... }:

{
  environment.systemPackages = [
    pkgs.davinci-resolve
  ];

  # Create required directories for DaVinci Resolve
  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/DaVinciResolve 0755 - - -"
    "d %h/.local/share/DaVinciResolve/license 0755 - - -"
  ];

  # OpenSnitch rule for DaVinci Resolve
  services.opensnitch.rules = {
    rule-500-davinci-resolve = {
      name = "Allow DaVinci Resolve network access";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "simple";
        sensitive = false;
        operand = "process.path";
        data = "${lib.getBin pkgs.davinci-resolve}/bin/davinci-resolve";
      };
    };
  };
} 