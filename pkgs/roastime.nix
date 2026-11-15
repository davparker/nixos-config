{ lib
, buildFHSEnv
, appimageTools
, fetchurl
, writeShellScript
, unzip
}:

let
  pname = "roastime";
  version = "latest";

  src = fetchurl {
    url = "https://api.roast.world/api/v3/roastime/main/lin/x64";
    name = "roastime.AppImage";
    hash = "sha256-sAG7kPUcfh8wXgbIgyPYFxa8ATMeoeyOoMG76LeDol8=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
buildFHSEnv (appimageTools.defaultFhsEnvArgs // {
  inherit pname version;

  extraBwrapArgs = [
    "--bind-try" "/etc/nixos" "/etc/nixos"
    "--dev-bind" "/dev" "/dev"
    "--ro-bind-try" "/run/udev" "/run/udev"
    "--tmpfs" "/run/dbus"
  ];

  targetPkgs = pkgs: (appimageTools.defaultFhsEnvArgs.targetPkgs pkgs) ++ (with pkgs; [
    libusb1
    systemd # provides libudev
    unzip
  ]);

  runScript = writeShellScript "roastime-run" ''
    DEPS_DIR="$HOME/.config/roastime/deps"

    # 1. Automatically extract pending downloaded comms updates if present
    if [ -f "$DEPS_DIR/roastime-comms-linux-x64.zip" ]; then
      ${unzip}/bin/unzip -qo "$DEPS_DIR/roastime-comms-linux-x64.zip" -d "$DEPS_DIR" 2>/dev/null || true
    fi

    # 2. Ensure executable permissions and create generic symlink
    if [ -d "$DEPS_DIR" ]; then
      chmod +x "$DEPS_DIR"/roastime-* 2>/dev/null || true
      ln -sf "$DEPS_DIR/roastime-comms-linux-x64" "$DEPS_DIR/roastime-comms" 2>/dev/null || true
    fi

    exec ${appimageContents}/AppRun "$@"
  '';

  extraInstallCommands = ''
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons

    # Desktop entry
    install -m 444 -D ${appimageContents}/roastime.desktop $out/share/applications/roastime.desktop 2>/dev/null || \
    install -m 444 -D ${appimageContents}/RoasTime.desktop $out/share/applications/roastime.desktop 2>/dev/null || true

    substituteInPlace $out/share/applications/roastime.desktop \
      --replace-quiet 'Exec=AppRun' "Exec=$out/bin/${pname}" \
      --replace-quiet 'Exec=roastime' "Exec=$out/bin/${pname}" || true

    # Icons
    cp -r ${appimageContents}/usr/share/icons $out/share/ 2>/dev/null || true
  '';

  meta = with lib; {
    description = "Roast profile logging software for Aillio Bullet R1";
    homepage = "https://roast.world";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
  };
})
