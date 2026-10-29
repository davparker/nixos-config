{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/accessibility.nix
    ./modules/thinkpad-hardware.nix
    ./modules/desktop-apps.nix
    ./modules/tailscale.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

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
      rebuild = "sudo nixos-rebuild switch";
    };
    interactiveShellInit = ''
      export EDITOR="nano"
      fastfetch
    '';
  };

  # Nix Package Manager - allow unfree
  nixpkgs.config.allowUnfree = true;

  # Expose custom derivations into pkgs.*
  nixpkgs.overlays = [
    (final: prev: import ./pkgs final)

    # Pin Tailscale to nixos-unstable
    (final: prev: {
      tailscale = (import <unstable> {
        system = prev.system;
        config = config.nixpkgs.config;
      }).tailscale;
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
