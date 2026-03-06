{ config, lib, pkgs, modulesPath, specialArgs, ... }: {  # Add specialArgs, ...
  
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  console.keyMap = "fr";
  i18n.defaultLocale = "fr_FR.UTF-8";

  image.baseName = lib.mkForce "kubenix-cp";
  isoImage.makeUsbBootable = lib.mkDefault true;
  isoImage.compressImage = false;

  # systemd-boot for EFI-only (simpler for modern ARM)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.hostPlatform = lib.mkDefault config.nixpkgs.system;
  
  # Networking configuration
  systemd.network.enable = true;

  systemd.network.networks."20-enp1s0" = {
    matchConfig.Name = "enp1s0";
    networkConfig = {
      DHCP = "yes";
      Address = [ "10.99.0.10/24" ];
    };
  };

  # Install dependencies
  environment.systemPackages = with pkgs; [
    #Setup utility
    disko
    # Enable installation from ISO
    gptfdisk
    rsync
    parted
    e2fsprogs
    # Add K8s/containerd tools to the live ISO
    kubernetes
    cri-tools
    # Helm package manager
    kubernetes-helm
    # Network troubleshooting (your workflow)
    tcpdump
    netcat
    # Air-gapped helpers
    kubectl
    crane
  ];

  # Enable SSH for post-boot access
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Enable Containerd
  virtualisation.containerd.enable = true;
 
  services.kubernetes = {
    roles = [ "master" ];
    masterAddress = "10.99.0.10";
    apiserverAddress = "10.99.0.10";
    easyCerts = true;
    kubelet = {
      enable = true;
    };
  };

  environment.etc."containerd/config.toml".text = ''
    version = 2
    [plugins."io.containerd.grpc.v1.cri"]
      sandbox_image = "registry.k8s.io/pause:3.10"
  '';

  # Create a group for kubeconfig access
  users.groups.kubeconfig = { };
  # Add your user to the group (adjust username)
  users.users.nixos.extraGroups = [ "kubeconfig" ];
  # Set permissions on the kubeconfig: 0640 root:kubeconfig
  systemd.tmpfiles.rules = [
    "f /etc/kubernetes/cluster-admin.kubeconfig 0640 root kubeconfig -"
  ];

  # Remove swap device
  swapDevices = [ ];

  boot.kernelModules = [ "br_netfilter" "overlay" ];

  # K8s networking (Cilium optimized)
  boot.kernel.sysctl = {
    "vm.swappiness" = 0;
    "net.ipv4.conf.all.rp_filter" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv6.conf.all.forwarding" = 1;
  };

}
