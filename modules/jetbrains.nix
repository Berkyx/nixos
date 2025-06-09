{ pkgs, lib, ... }:
let 
  rustRoverPath = "${lib.getBin pkgs.jetbrains.rust-rover}/rust-rover/bin/.rustrover-wrapped";
  webstormPath = "${lib.getBin pkgs.jetbrains.webstorm}/webstorm/bin/.webstorm-wrapped";
  datagripPath = "${lib.getBin pkgs.jetbrains.datagrip}/datagrip/bin/.datagrip-wrapped";
  
  jetbrainsProcessRules = [
    {
      type = "simple";
      sensitive = false;
      operand = "process.path";
      data = rustRoverPath;
    }
    {
      type = "simple";
      sensitive = false;
      operand = "process.path";
      data = webstormPath;
    }
    {
      type = "simple"; 
      sensitive = false;
      operand = "process.path";
      data = datagripPath;
    }
  ];
in

{
  environment.systemPackages = with pkgs.jetbrains; [
    rust-rover
    webstorm
    datagrip
  ];

  services.opensnitch.rules = {
    rule-500-jetbrains-to-jetbrains = {
      name = "Allow Jetbrains tools to phone home";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = jetbrainsProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^([a-z0-9|-]+\\.)*jetbrains\\.com$";
          }
        ];
      };
    };
    rule-500-jetbrains-to-github = {
      name = "Allow Jetbrains tools to reach GitHub";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = jetbrainsProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^(github\\.com|raw\\.githubusercontent\\.com)$";
          }
        ];
      };
    };

    rule-500-jetbrains-to-npm = {
      name = "Allow Jetbrains tools to contact npm";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = jetbrainsProcessRules ++ [
          {
            type = "simple";
            operand = "dest.host";
            sensitive = false;
            data = "registry.npmjs.org";
          }
        ];
      };
    };
    rule-500-jetbrains-to-schemastore = {
      name = "Allow Jetbrains tools to reach schemastore";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = jetbrainsProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^([a-z0-9|-]+\\.)*schemastore\\.org$";
          }
        ];
      };
    };
    rule-500-jetbrains-to-pypi = {
      name = "Allow Jetbrains tools to reach out to pypi";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = jetbrainsProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^pypi.python.org|pypi.org$";
          }
        ];
      };
    };
  };
}