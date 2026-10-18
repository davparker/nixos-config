# This file exports all custom derivations in pkgs/
# add my-tool = pkgs.callPackage ./my-tool.nix { }; here.
pkgs: {
  roastime = pkgs.callPackage ./roastime.nix { };
}

