# nix-agent

Packages [kolide/launcher](https://github.com/kolide/launcher) for Nix.

> [!WARNING]
> Please note that the ARM64 version is in beta.

## Running kolide-launcher

Include `kolide-launcher` in your `/etc/nixos/flake.nix` inputs:

```
kolide-launcher = {
  url = "github:/kolide/nix-agent/main";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Deploy your enrollment secret to `/etc/kolide-k2/secret`. This can be done e.g.
by adding it to `/etc/nixos/configuration.nix`:

```
environment.etc."kolide-k2/secret" = {
  mode = "0600";
  text = "<enrollment secret goes here>";
};
```

The enrollment secret can be discovered by viewing `/etc/kolide-k2/secret` (on macOS/Linux)
or `C:\Program Files\Kolide\Launcher-kolide-k2\conf\secret` (on Windows) on an existing
installation. If an existing installation is not available, then the secret may be extracted
from one of the packages available for your tenant -- e.g. you can download `kolide-launcher.deb`,
run `nix-shell -p dpkg` to make the `dpkg-deb` tool available, and then use `dpkg-deb` to extract
the contents of the deb and view the resulting `<archive directory>/etc/kolide-k2/secret` file.

This enrollment secret should be kept confidential.

In `/etc/nixos/configuration.nix`, ensure that the kolide-launcher service is enabled:

```
services.kolide-launcher.enable = true;
```

## Developing and testing in a VM

Create a VM using a NixOS 23.11 image with flakes enabled and SSH to the new VM.

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

### Setting up your enrollment secret

You can manually create your secret file:

```
echo -n 'your-enroll-secret-goes-here' | sudo tee /etc/kolide-k2/secret
```

Then start the `kolide-launcher.service` service.

You can also configure the secret in `/etc/nixos/configuration.nix`.

```
environment.etc."kolide-k2/secret" = {
  mode = "0600";
  text = "<enrollment secret goes here>";
};
```

### Running tests

[NixOS tests](https://nixos.org/manual/nixos/stable/index.html#sec-nixos-tests)
live in the [./tests](./tests) directory and are included via flake checks.
They are currently intended to run in CI only.

#### Running the mock agent server

To run the mock agent server locally for testing purposes, you can run
`python3 -m flask --app agentserver run` from the `tests` directory.
