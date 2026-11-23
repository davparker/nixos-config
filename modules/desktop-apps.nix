{ pkgs, ... }:

let
  # Custom Gemini desktop entry
  gemini-icon = pkgs.fetchurl {
    url = "https://www.gstatic.com/lamda/images/gemini_sparkle_v002_d4735304ff6292a690345.svg";
    sha256 = "sha256-AYIUlFk7gf/X2g4IKH1HNTBP9ikqaQNFMyi50Xzzh5k=";
  };

  gemini-desktop = pkgs.symlinkJoin {
    name = "gemini-desktop";
    paths = [
      (pkgs.makeDesktopItem {
        name = "gemini";
        desktopName = "Google Gemini";
        genericName = "AI Assistant";
        comment = "Google Gemini Conversational AI";
        exec = "${pkgs.brave}/bin/brave --app=https://gemini.google.com/app %U";
        icon = "google-gemini";
        terminal = false;
        categories = [ "Network" "Utility" "Chat" ];
        startupWMClass = "gemini.google.com";
      })
    ];
    postBuild = ''
      mkdir -p $out/share/icons/hicolor/scalable/apps
      ln -s ${gemini-icon} $out/share/icons/hicolor/scalable/apps/google-gemini.svg
    '';
  };
in
{
  # 1. Custom RoasTime overlay (must live inside the returned module attrset, after `in`)
  nixpkgs.overlays = [
    (final: prev: {
      roastime = final.callPackage ../pkgs/roastime.nix { };
    })
  ];

  # AppImage binary format support (for RoasTime)
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Browsers
  programs.firefox.enable = true;
  programs.chromium = {
    enable = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden extension
    ];
  };

  # Global system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    fastfetch            # system info summary tool
    tailscale
    appimage-run
    brave
    gemini-desktop
    roastime             # Built natively from roastime.nix, imported pkgs overlay
    git
    hicolor-icon-theme
    adwaita-icon-theme
    bitwarden-desktop
    vscode
    sof-firmware
    alsa-utils
    pavucontrol
    ffmpeg
    pulseaudio
    tree
    rustdesk-flutter
  ];
}
