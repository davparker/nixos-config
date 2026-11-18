
{
  description = "NixOS system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      mkHost = hostConfig: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          hostConfig
        ];
      };
    in {
      nixosConfigurations = {
        t14-g7 = mkHost ./hosts/t14-g7/configuration.nix;
        x1c-g4 = mkHost ./hosts/x1c-g4/configuration.nix;
      };
    };
}
