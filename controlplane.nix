{ config, lib, pkgs, modulesPath, specialArgs, ... }: {  # Add specialArgs, ...
  imports = [ 
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") 
  ];

  image.baseName = lib.mkForce "controlplane-kubeadm";

  # systemd-boot for EFI-only (simpler for modern ARM)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  nixpkgs.hostPlatform = lib.mkDefault config.nixpkgs.system;
}

