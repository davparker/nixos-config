{ pkgs, ... }:

{
  # Firmware & Kernel Modules
  hardware.enableAllFirmware = true;
  boot.kernelModules = [ "thinkpad_acpi" ];

  # Bluetooth in GNOME
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # USB rules: Aillio Bullet roaster access & Mic-mute LED write permissions
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5741", MODE="0666", GROUP="dialout"
    ACTION=="add|change", SUBSYSTEM=="leds", KERNEL=="*micmute", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/leds/%k/brightness"
  '';

  # PipeWire with Echo Cancellation & AGC
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    extraConfig.pipewire."99-mic-echo-cancel" = {
      "context.modules" = [
        {
          name = "libpipewire-module-echo-cancel";
          args = {
            "source.props" = {
              "node.name" = "echo-cancel-source";
              "node.description" = "ThinkPad PDM Mic (Echo Cancel & AGC)";
            };
            "aec.args" = {
              "webrtc.gain_control" = true;
              "webrtc.noise_suppression" = true;
              "webrtc.voice_detection" = true;
            };
          };
        }
      ];
    };
  };

  # Real-time microphone mute LED synchronization service
  systemd.user.services.thinkpad-mic-led-sync = {
    description = "Sync ThinkPad Mic Mute LED with PipeWire Default Source";
    after = [ "pipewire.service" "wireplumber.service" ];
    wantedBy = [ "default.target" ];
    path = with pkgs; [ pulseaudio coreutils gnugrep ];
    script = ''
      update_led() {
        if pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -q "yes"; then
          echo 1 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
        else
          echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
        fi
      }

      update_led

      pactl subscribe 2>/dev/null | while read -r event; do
        if echo "$event" | grep -q "source"; then
          update_led
        fi
      done
    '';
  };
}
