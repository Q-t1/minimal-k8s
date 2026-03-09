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
      server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./os_configuration.nix
          ./kubernetes.nix
        ];
      };

      installer = unattended.lib.diskoInstallerWrapper self.nixosConfigurations.server { };
    };

    packages.${system}.iso = self.nixosConfigurations.installer.config.system.build.isoImage;
  };
}
