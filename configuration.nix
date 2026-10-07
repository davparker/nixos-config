# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
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

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.enable = true; 

  # Allow non-root access for Aillio Bullet USB controller
    services.udev.extraRules = ''
      SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5741", MODE="0666", GROUP="dialout"
       SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="a27e", MODE="0666", GROUP="dialout"
    '';


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;    

  # Enable the keyd system service
  services.keyd.enable = false;

  # enable tailscale
  services.tailscale.enable = true;

  # Mouse click lock
  # Imtercept middle button
  systemd.services.trackpoint-toggle = {
    description = "Trackpoint Middle-to-Left Toggle Latch";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "2s";
      ExecStart = ''
        ${pkgs.evsieve}/bin/evsieve \
          --input /dev/input/by-path/platform-i8042-serio-1-event-mouse grab \
          --map btn:middle:1 btn:left@toggle \
          --output
      '';
    };
  }; 
  
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."david" = {
    isNormalUser = true;
    description = "David";
    extraGroups = [ "dialout" "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Bitwarden browser extension
  programs.chromium = {
    enable = true;
    extensions = [
      # Bitwarden extension ID from the Chrome Web Store
      "nngceckbapebfimnlniiiahkandclblb"
    ];
  };

  # RoasTime
    programs.appimage = {
      enable = true;
      binfmt = true;
  };

  # Bash
  programs.bash = {
    shellAliases = {
      ll = "ls -la";
      rebuild = "sudo nixos-rebuild switch";
    };
    interactiveShellInit = ''
      # Put custom interactive shell scripts or exports here
      export EDITOR="nano"
    '';
  }; 

  # Enforce Sticky Keys
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/desktop/a11y/keyoard" = {
        stickykeys-enable = true;
        stickykeys-two-key-off = false;
      };
    };
  }];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    keyd
    tailscale
    appimage-run
    brave
    git
    hicolor-icon-theme
    adwaita-icon-theme
    pkgs.evsieve
    bitwarden-desktop
    vscode
#    quickdrag # Gnome click lock
#    quickdrag end
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # Tailscale
  networking.firewall = {
    # Allow Tailscale's default UDP port for direct peer-to-peer tunnels
    allowedUDPPorts = [ config.services.tailscale.port ];

    # Trust the tailscale0 virtual network interface
    trustedInterfaces = [ "tailscale0" ];
  };

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
