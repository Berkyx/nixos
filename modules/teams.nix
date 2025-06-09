{pkgs, lib, ... }:
{
  environment.systemPackages = [
    pkgs.teams
  ];

  services.opensnitch.rules = {
    rule-900-teams = {
      name = "Allow Teams Rule";
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
          data = "${lib.getBin pkgs.teams}/lib/teams/teams";
        }
        ];
      };
    };
  };
}
