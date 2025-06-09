{ pkgs, ... }:

let
  appImagePath = "/home/berkay/Appimages/Cursor-0.50.5-x86_64.AppImage";
  appName = "cursor";
  displayName = "Cursor";
  description = "Code Editor";
  categories = [ "Development" ];
  
   cursorWrapper = pkgs.writeShellScriptBin appName ''
    #!${pkgs.bash}/bin/bash
    if [ -f "${appImagePath}" ]; then
      exec ${pkgs.appimage-run}/bin/appimage-run "${appImagePath}" "$@"
    else
      echo "Error: AppImage not found at ${appImagePath}"
      echo "Please ensure Cursor AppImage is located at: ${appImagePath}"
      exit 1
    fi
  '';

in
{
   home.packages = [
    pkgs.appimage-run
    cursorWrapper
  ];

   xdg.desktopEntries.cursor = {
    name = displayName;
    comment = description;
    exec = "${cursorWrapper}/bin/${appName} %U";
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
