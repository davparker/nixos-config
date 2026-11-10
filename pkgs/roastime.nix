{ lib
, buildFHSEnv
, appimageTools
, fetchurl
, writeShellScript
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
  ];

  targetPkgs = pkgs: (appimageTools.defaultFhsEnvArgs.targetPkgs pkgs) ++ (with pkgs; [
    libusb1
    systemd # provides libudev
  ]);

  runScript = writeShellScript "roastime-run" ''
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
