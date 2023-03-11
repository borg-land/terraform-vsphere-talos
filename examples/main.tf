
provider "vsphere" {
  # LOAD IT VIA ENV
}

module "talos" {
  source            = "../../talos"
  talos_version     = "v1.3.4"
  kube_cluster_name = "prime"

  controlplane_name_prefix = "dev-master"
  controlplane_nodes       = 1
  controlplane_memory      = "4096"
  controlplane_cpu         = "4"
  controlplane_disk_size   = "20"

  worker_name_prefix = "dev-worker"
  worker_nodes       = 1
  worker_memory      = "8192"
  worker_cpu         = "8"
  worker_disk_size   = 20

  # Vsphere Config
  vsphere_datacenter    = "Home"
  vsphere_resource_pool = "Resources"
  vsphere_datastore     = "nvme-b"
  vsphere_host          = "10.150.2.7"
  vsphere_cluster       = ""
  vsphere_network       = "LAN - Servers"
  talos_config_path     = "./talos-config/"

  # Networking
  talos_cluster_endpoint = "10.150.9.201"
  cert_sans = [
    "talos.k8s.foo.bar"
  ]
  ip_gateway = "10.150.8.1"
  ip_netmask = "/22"
  nameservers = [
    "10.150.8.1",
  ]
  dns_domain                    = "upo.lan"
  ip_address_base               = "10.150.9"
  controlplane_ip_address_start = "10"
  worker_ip_address_start       = "13"

  # Kubernetes Config
  pod_subnets = [
    "10.245.0.0/19"
  ]
  service_subnets = [
    "10.245.32.0/19"
  ]
  custom_cni         = true
  disable_kube_proxy = false

  kubelet = {
    extraArgs = {
      rotate-server-certificates = true
    }
    # extraConfig = {
    #   serverTLSBootstrap = "true"
    # } // currently broken
    extraMounts = [{
      destination = "/var/openebs/local"
      options = [
        "bind",
        "rshared",
        "rw"
      ]
      source = "/var/openebs/local"
      type   = "bind"
      }
    ]
  }


  # Generated values using talos_certificates.sh
  kube_crt           = var.kube_crt
  kube_key           = var.kube_key
  talos_crt          = var.talos_crt
  talos_key          = var.talos_key
  etcd_crt           = var.etcd_crt
  etcd_key           = var.etcd_key
  admin_crt          = var.admin_crt
  admin_key          = var.admin_key
  talos_token        = var.talos_token
  kube_token         = var.kube_token
  kube_enc_key       = var.kube_enc_key
  serviceaccount_key = var.serviceaccount_key
  aggregator_crt     = var.aggregator_crt
  aggregator_key     = var.aggregator_key
}
