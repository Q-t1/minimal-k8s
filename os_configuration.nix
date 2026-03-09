{ config, pkgs, ... }:
{
  disko.devices = {
    disk = {
      my-disk = {
        device = "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };

  users.users.kubxadm.isSystemUser = false;
  users.users.kubxadm.isNormalUser = true;
  users.users.kubxadm.group = "nixos";
  users.groups.nixos = {};

  users.users.kubxadm.initialPassword = "verysecret";
  system.stateVersion = "25.11";

  console.keyMap = "fr";
  i18n.defaultLocale = "fr_FR.UTF-8";

  # systemd-boot for EFI-only (simpler for modern ARM)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Networking configuration
  systemd.network.enable = true;
  networking.hostName = "kubx";
  networking.useNetworkd = true;

  systemd.network.networks."20-enp1s0" = {
    matchConfig.Name = "enp1s0";
    networkConfig = {
      DHCP = "yes";
      Address = [ "10.99.0.10/24" ];
    };
  };

  # Enable SSH for post-boot access
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

}