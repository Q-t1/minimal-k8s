{
  description = "Kubeadm NixOS ISOs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let

  system =  "aarch64-linux";

  in {
    nixosConfigurations = {
      os-iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./os-iso.nix ];
      };
      controlplane = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./controlplane.nix ];
      };
      worker = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./worker.nix ];
      };
    };

    packages.${system} = {
      os-iso = self.nixosConfigurations.os-iso.config.system.build.image;
      controlplane-iso = self.nixosConfigurations.controlplane.config.system.build.image;
      worker-iso = self.nixosConfigurations.worker.config.system.build.image;
      default = self.packages.${system}.controlplane-iso;
    };

  };
}

