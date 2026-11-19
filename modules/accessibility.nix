{ pkgs, ... }:

{
  boot.kernelModules = [ "uinput" ];

  # Native Windows-style ClickLock daemon for ThinkPad TrackPoint
  systemd.services.windows-clicklock = {
    description = "Windows ClickLock Daemon for TrackPoint";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "2s";

      ExecStart = "${pkgs.writeScriptBin "clicklock" ''
        #!${pkgs.python3.withPackages (ps: [ ps.evdev ])}/bin/python3
        import sys
        import time
        from evdev import InputDevice, UInput, ecodes, list_devices

        dev = None
        for path in list_devices():
            candidate = InputDevice(path)
            if "TrackPoint" in candidate.name:
                dev = candidate
                break

        if dev is None:
            sys.exit(1)

        caps = {
            ecodes.EV_KEY: [
                ecodes.BTN_LEFT,
                ecodes.BTN_RIGHT,
                ecodes.BTN_MIDDLE,
            ],
            ecodes.EV_REL: [
                ecodes.REL_X,
                ecodes.REL_Y,
                ecodes.REL_WHEEL,
            ],
        }
        ui = UInput(caps, name="TrackPoint ClickLock Mouse")
        dev.grab()

        is_locked = False
        press_time = 0.0
        lock_threshold = 0.40  # 400ms hold locks left click down

        for event in dev.read_loop():
            if event.type == ecodes.EV_KEY and event.code == ecodes.BTN_LEFT:
                if event.value == 1:
                    press_time = time.time()
                    if is_locked:
                        is_locked = False
                        ui.write(ecodes.EV_KEY, ecodes.BTN_LEFT, 0)
                        ui.syn()
                        continue
                    ui.write(ecodes.EV_KEY, ecodes.BTN_LEFT, 1)
                    ui.syn()
                elif event.value == 0:
                    duration = time.time() - press_time
                    if duration >= lock_threshold:
                        is_locked = True
                    else:
                        if not is_locked:
                            ui.write(ecodes.EV_KEY, ecodes.BTN_LEFT, 0)
                            ui.syn()

            elif (
                event.type == ecodes.EV_KEY
                and event.code == ecodes.BTN_MIDDLE
                and event.value == 1
            ):
                is_locked = not is_locked
                ui.write(
                    ecodes.EV_KEY,
                    ecodes.BTN_LEFT,
                    1 if is_locked else 0,
                )
                ui.syn()

            else:
                ui.write(event.type, event.code, event.value)
                ui.syn()
      ''}/bin/clicklock";
    };
  };

  # Enforce Sticky Keys in GNOME
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/desktop/a11y/keyboard" = {
        stickykeys-enable = true;
        stickykeys-two-key-off = false;
      };
    };
  }];
}
