{ config, lib, modulesPath, ... }:

{
    imports = 
    [
        (modulesPath + "/installer/scan/not-detected.nix")
        ./base.nix
        ./modules/encrypted-dns.nix
        ./modules/server.nix
    ];

    boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "berkay-laptop";

    fileSystems."/" =
        { 
            device = "/dev/disk/by-uuid/c1a4d85c-e76e-4a53-8fad-71fe62e648d3";
            fsType = "ext4";
        };

    fileSystems."/boot" =
        { 
            device = "/dev/disk/by-uuid/E505-4205";
            fsType = "vfat";
            options = [ "fmask=0077" "dmask=0077" ];
        };

    swapDevices = [ ];

    networking.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    hardware.graphics = {
        enable = true;
    };
  
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {

        # Modesetting is required.
        modesetting.enable = true;

        # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
        # Enable this if you have graphical corruption issues or application crashes after waking
        # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
        # of just the bare essentials.
        powerManagement.enable = false;

        # Fine-grained power management. Turns off GPU when not in use.
        # Experimental and only works on modern Nvidia GPUs (Turing or newer).
        powerManagement.finegrained = false;

        # Use the NVidia open source kernel module (not to be confused with the
        # independent third-party "nouveau" open source driver).
        # Support is limited to the Turing and later architectures. Full list of 
        # supported GPUs is at: 
        # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
        # Only available from driver 515.43.04+
        open = true;

        # Enable the Nvidia settings menu,
            # accessible via `nvidia-settings`.
        nvidiaSettings = true;

        # Optionally, you may need to select the appropriate driver version for your specific GPU.
        package = config.boot.kernelPackages.nvidiaPackages.latest;

        prime = {
            offload = {
                    enable = true;
                    enableOffloadCmd = true;
            };
            # Make sure to use the correct Bus ID values for your system!
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
        };
    };
}