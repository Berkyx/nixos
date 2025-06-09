{ pkgs, lib, ... }:
let 
  androidStudioPath = "${lib.getBin pkgs.android-studio}/android-studio/bin/.android-studio-wrapped";
  
  # Import android-nixpkgs for comprehensive Android SDK
  android-nixpkgs = pkgs.callPackage (builtins.fetchGit {
    url = "https://github.com/tadfisher/android-nixpkgs.git";
    ref = "stable";  # Use stable channel
  }) {
    channel = "stable";
  };

  # Create a complete Android SDK with emulator support
  android-sdk = android-nixpkgs.sdk (sdkPkgs: with sdkPkgs; [
    cmdline-tools-latest
    build-tools-34-0-0
    build-tools-35-0-0 
    platform-tools
    platforms-android-34
    platforms-android-35 
    emulator             
    system-images-android-34-google-apis-x86-64
    system-images-android-35-google-apis-x86-64
    sources-android-34
    sources-android-35
  ]);
  
  androidStudioProcessRules = [
    {
      type = "simple";
      sensitive = false;
      operand = "process.path";
      data = androidStudioPath;
    }
  ];
in

{
  environment.systemPackages = with pkgs; [
    android-studio
    android-sdk  # Include the complete SDK
    # Additional useful tools for Android development
    scrcpy      # Screen mirroring for Android devices
    adb-sync    # Sync files to Android devices
  ];

  # Enable hardware acceleration for Android emulator
  programs.adb.enable = true;
  
  # Add user to adbusers group for device access
  users.groups.adbusers = {};

  services.opensnitch.rules = {
    rule-500-android-studio-to-google = {
      name = "Allow Android Studio to reach Google services";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = androidStudioProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^([a-z0-9|-]+\\.)*google\\.com$";
          }
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^([a-z0-9|-]+\\.)*googleapis\\.com$";
          }
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^([a-z0-9|-]+\\.)*android\\.com$";
          }
          {
            type = "simple";
            operand = "dest.host";
            sensitive = false;
            data = "dl.google.com";
          }
        ];
      };
    };
    rule-500-android-studio-to-github = {
      name = "Allow Android Studio to reach GitHub";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = androidStudioProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^(github\\.com|raw\\.githubusercontent\\.com)$";
          }
        ];
      };
    };
    rule-500-android-studio-to-maven = {
      name = "Allow Android Studio to reach Maven repositories";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = androidStudioProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^([a-z0-9|-]+\\.)*maven\\.org$";
          }
          {
            type = "simple";
            operand = "dest.host";
            sensitive = false;
            data = "repo1.maven.org";
          }
          {
            type = "simple";
            operand = "dest.host";
            sensitive = false;
            data = "central.maven.org";
          }
        ];
      };
    };
    rule-500-android-studio-to-gradle = {
      name = "Allow Android Studio to reach Gradle services";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = androidStudioProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^([a-z0-9|-]+\\.)*gradle\\.org$";
          }
          {
            type = "simple";
            operand = "dest.host";
            sensitive = false;
            data = "services.gradle.org";
          }
        ];
      };
    };
    rule-500-android-studio-to-jcenter = {
      name = "Allow Android Studio to reach JCenter repository";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = androidStudioProcessRules ++ [
          {
            type = "simple";
            operand = "dest.host";
            sensitive = false;
            data = "jcenter.bintray.com";
          }
        ];
      };
    };
    rule-500-android-studio-to-kotlinlang = {
      name = "Allow Android Studio to reach Kotlin language services";
      enabled = true;
      action = "allow";
      duration = "always";
      operator = {
        type = "list";
        operand = "list";
        list = androidStudioProcessRules ++ [
          {
            type = "regexp";
            operand = "dest.host";
            sensitive = false;
            data = "^([a-z0-9|-]+\\.)*kotlinlang\\.org$";
          }
        ];
      };
    };
  };

  # Environment variables for Android development
  environment.sessionVariables = {
    ANDROID_HOME = "${android-sdk}/share/android-sdk";
    ANDROID_SDK_ROOT = "${android-sdk}/share/android-sdk";
  };

  # Enable virtualization support for Android emulator
  virtualisation = {
    libvirtd.enable = true;
  };
  
  # Add KVM support for hardware acceleration
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
} 