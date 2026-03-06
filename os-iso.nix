{ modulesPath, lib, pkgs, config, ... }: {
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  console.keyMap = "fr";
  i18n.defaultLocale = "fr_FR.UTF-8";

  image.baseName = lib.mkForce "kubenix-cp";
  isoImage.makeUsbBootable = lib.mkDefault true;
  isoImage.compressImage = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    vim rsync parted gptfdisk disko
  ];

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Inline disko config (no external flake ref)
  environment.etc."disko.nix".text = ''
    {
      nodev = { type = "nodev"; };
      disk.vda = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions.ESP = {
            size = "512M"; type = "EF00";
            content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; };
          };
          partitions.root = {
            size = "100%";
            content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; };
          };
        };
      };
    }
  '';

  systemd.services.nixos-auto-install = {
    enable = true;
    description = "Decl. NixOS flake install";
    wantedBy = [ "multi-user.target" ];
    requires = [ "dev-vda.device" ];
    after = [ "dev-vda.device" ];
    before = [ "multi-user.target" ];
    script = ''
      #!/bin/sh
      set -euxo pipefail
      export NIX_CONFIG="experimental-features = nix-command flakes"
      PATH=${lib.makeBinPath config.environment.systemPackages}:$PATH
      # Apply disko
      disko --mode destroy,format,mount /mnt
      # Gen hw config
      nixos-generate-config --root /mnt
      # Install flake (REPLACE with your actual repo!)
      #nixos-install --flake github:YOURUSER/kubenix-cp#cp --no-root-passwd
      reboot
    '';
    serviceConfig = {
      Type = "oneshot";
      TimeoutStopSec = 900;
    };
  };
}
