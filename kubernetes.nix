{ config, pkgs, ... }:
{

  # Install dependencies
  environment.systemPackages = with pkgs; [
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
  users.users.kubxadm.extraGroups = [ "kubeconfig" ];
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