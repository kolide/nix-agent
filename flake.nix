{
  description = "Kolide launcher";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.kolide-launcher =
      let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ self.overlays.default ];
        };
      in
      pkgs.kolide-launcher;

    overlays.default = final: prev: {
      kolide-launcher = final.callPackage ./kolide-launcher.nix { };
    };

    packages.x86_64-linux.default = self.packages.x86_64-linux.kolide-launcher;

    nixosModules.kolide-launcher = import ./modules/kolide-launcher;

    checks.x86_64-linux.kolide-launcher = import ./tests/kolide-launcher.nix;
  };
}
