{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/accessibility.nix
    ./modules/thinkpad-hardware.nix
    ./modules/desktop-apps.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Tailscale forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;

    # Increase maximum buffer size limits (e.g. up to 16MB)
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;

    # Increase default socket buffer sizes (e.g. up to 1MB)
    "net.core.rmem_default" = 1048576;
    "net.core.wmem_default" = 1048576;

    # Increase maximum backlog of queued incoming packets
    "net.core.netdev_max_backlog" = 10000;  
  };

  # Networking
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both"; # Options: "client", "server", or "both"
  };

  networking.firewall = {
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" ];
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
  ];

  # Enable nix garbage collect
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "26.05";
}
