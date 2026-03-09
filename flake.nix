{
  description = "NixOS kubeadm server bootstrap ISO (aarch64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    unattended.url = "github:chrillefkr/nixos-unattended-installer";  # rename to avoid conflict
  };

  outputs = { self, nixpkgs, disko, unattended }: let
    system = "aarch64-linux";
  in {
    nixosConfigurations = {
      system = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./os_configuration.nix
          ./kubernetes.nix
        ];
      };

      k8s-controlplane = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./os_configuration.nix
          ./kubernetes-master.nix
        ];
      };

      k8s-worker = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./os_configuration.nix
          ./kubernetes-worker.nix
        ];
      };

      # Installers
      installer-system = unattended.lib.diskoInstallerWrapper self.nixosConfigurations.system { };
      installer-k8s = unattended.lib.diskoInstallerWrapper self.nixosConfigurations.kubernetes { };
    };

    packages.${system} = {
      iso-base = self.nixosConfigurations.installer-system.config.system.build.isoImage;
      iso-k8s  = self.nixosConfigurations.installer-k8s.config.system.build.isoImage;
    };  };
}
