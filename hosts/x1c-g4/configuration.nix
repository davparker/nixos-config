{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/accessibility.nix
    ../../modules/thinkpad-hardware.nix
    ../../modules/desktop-apps.nix
    ../../modules/tailscale.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Networking
  networking.hostName = "x1c-g4";
  networking.networkmanager.enable = true;

  # For TP X1 Carbon soldered RAM
  zramSwap.enable = true;

  # Base Firewall (Tailscale-specific rules are merged from modules/tailscale.nix)
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Localization & Time
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Desktop Environment: GNOME on Wayland
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Printing & Remote Access
  services.printing.enable = true;
  services.openssh.enable = true;

  # Aillio Bulllet USB
  services.udev.extraRules = ''
    # Aillio Bullet R1 (Normal mode: 0483:a27e and legacy 0483:5740)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="a27e", MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="5740", MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"
    KERNEL=="ttyACM[0-9]*", ATTRS{idVendor}=="0483", MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"

    # Aillio Bullet DFU Bootloader Mode (Comms firmware flashing)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="df11", MODE="0666", GROUP="dialout"
  '';

  # Enable nix-ld Roastime USB
  programs.nix-ld = {
    enable = true;
      libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      libusb1
      systemd # provides libudev
      glibc
    ];
  };

  # Disable Gnome power saving
  services.power-profiles-daemon.enable = false;
  
  services.tlp = {
    enable = true;
    settings = {
      # CPU governors
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_BOOST_ON_AC = 1;

      # Platform profiles (ThinkPad ACPI)
      PLATFORM_PROFILE_ON_AC = "performance";

      # Storage and bus power saving
      AHCI_RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_AC = "on";
      PCIE_ASPM_ON_AC = "performance";

      # Wi-Fi
      WIFI_PWR_ON_AC = "off";

      # Audio
      SOUND_POWER_SAVE_ON_AC = 0;
    };
  };

  # User Configuration
  users.users."david" = {
    isNormalUser = true;
    description = "David";
    extraGroups = [ "dialout" "networkmanager" "wheel" ];
  };

  # Shell Configuration
  programs.bash = {
    shellAliases = {
      ll = "ls -la";
      rebuild = "sudo nixos-rebuild switch --flake /home/david/nixos-config";
    };
    interactiveShellInit = ''
      export EDITOR="nano"
      fastfetch
    '';
  };

  # Nix Package Manager - allow unfree
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (final: prev: {
      roastime = final.callPackage ../../pkgs/roastime.nix { };
    })
  ];

  # Enable nix garbage collect
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "26.05";
}
