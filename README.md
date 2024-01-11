# nix-agent

Packages [kolide/launcher](https://github.com/kolide/launcher) for Nix.

## Developing and testing in a VM

Create a VM using a NixOS 23.05 image with flakes enabled and SSH to the new VM.

Make a directory for the launcher flake and copy your changes to `flake.nix` and `flake.lock` into it.
Make the subdirectory `modules/kolide-launcher` and copy your changes to `default.nix` into it.

Validate the flake with `NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure`; view info
about it with `nix flake show` and `nix flake metadata`.

Build the flake with `NIXPKGS_ALLOW_UNFREE=1 nix build --impure`. If all goes well,
you will have a new `result` directory that symlinks to the Nix store location
`/nix/store/<...>-kolide-launcher`.

Update your `/etc/nixos/configuration.nix` file to include and enable the launcher service;
adjust other config values as needed:

```
{ inputs }:
{ config, pkgs, ... }:
{
  # ...
  environment.systemPackages = with pkgs; [
    # ...
    inputs.kolide-launcher
  ];

  services.kolide-launcher = {
    enable = true;
    kolideHostname = "k2device-preprod.kolide.com";
    rootDirectory = "/var/kolide-k2/k2device-preprod.kolide.com";
    updateChannel = "nightly";
  };
}
```

Update your `/etc/nixos/flake.nix` file to include `kolide-launcher` in its input and output:

```
{
  # ...

  inputs = {
    kolide-launcher = {
      url = "path:/path/to/your/kolide-launcher/flake/directory";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, kolide-launcher, ... }@inputs: {
    nixosConfigurations = {
      "my-hostname" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (import ./configuration.nix { inherit inputs; })
          kolide-launcher.nixosModules.kolide-launcher
        ];
      };
    };
  };
}
```

Then rebuild: `sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch --flake /etc/nixos#my-hostname --impure`.

For now, you'll want to manually create your secret file:

```
echo -n 'your-enroll-secret-goes-here' | sudo tee /etc/kolide-k2/secret
```

Then start the `kolide-launcher.service` service.

### Running tests

[NixOS tests](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)
live in the [./tests](./tests) directory and are included via flake checks.
They are able to be run via the `nix flake check` command.
