{ pkgs, ... }:

let
  appImagePath = "/home/berkay/Appimages/Obsidian-1.8.10.AppImage";
  appName = "obsidian";
  displayName = "Obsidian";
  description = "Note App";
  categories = [ "Development" ];
  
   obsidianWrapper = pkgs.writeShellScriptBin appName ''
    #!${pkgs.bash}/bin/bash
    if [ -f "${appImagePath}" ]; then
      exec ${pkgs.appimage-run}/bin/appimage-run "${appImagePath}" "$@"
    else
      echo "Error: AppImage not found at ${appImagePath}"
      echo "Please ensure ${appName} AppImage is located at: ${appImagePath}"
      exit 1
    fi
  '';

in
{
   home.packages = [
    pkgs.appimage-run
    obsidianWrapper
  ];

   xdg.desktopEntries.obsidian = {
    name = displayName;
    comment = description;
    exec = "${obsidianWrapper}/bin/${appName} %U";
    icon = appName;
    categories = categories;
    startupNotify = true;
    terminal = false;
  };

   home.sessionVariables = {
    APPIMAGE_EXTRACT_AND_RUN = "1";
  };

   xdg.enable = true;
}
