version: v1alpha1 # Indicates the schema used to decode the contents.
debug: false # Enable verbose logging to the console.
persist: true # Indicates whether to pull the machine config upon every boot.
# Provides machine specific configuration options.
machine:
    type: ${type} # Defines the role of the machine within the cluster.
    token: ${talos_token} # The `token` is used by a machine to join the PKI of the cluster.
%{ if type != "worker" ~}
    # The root certificate authority of the PKI.
    ca:
        crt: ${talos_crt}
        key: ${talos_key}
%{ endif ~}
    # Used to provide additional options to the kubelet.
    kubelet:
        image: ghcr.io/siderolabs/kubelet:v1.26.1 # The `image` field is an optional reference to an alternative kubelet image.
        defaultRuntimeSeccompProfileEnabled: true # Enable container runtime default Seccomp profile.
        disableManifestsDirectory: true # The `disableManifestsDirectory` field configures the kubelet to get static pod manifests from the /etc/kubernetes/manifests directory.

    features:
      rbac: true # Enable role-based access control (RBAC).
      stableHostname: true # Enable stable default hostname.
      apidCheckExtKeyUsage: true # Enable checks for extended key usage of client certificates in apid.

    # Provides machine specific network configuration options.
%{if customize_network ~}
    network:
      hostname: ${hostname}
      interfaces:
      - interface: eth0
        cidr: ${node_ip_address}${ip_netmask}
        routes:
        - network: 0.0.0.0/0
          gateway: ${ip_gateway}
        mtu: 1500
        dhcp: false
        vip:
          ip: 10.150.9.200 

      nameservers:
%{for ns in nameservers ~}
      - ${ns}
%{endfor ~}
%{else ~}
    network: {}
%{endif ~}

    # Used to provide instructions for installations.
    install:
      disk: /dev/sda # The disk used for installations.
      image: ghcr.io/talos-systems/installer:${tf_talos_version} # Allows for supplying the image used to perform the installation.
      bootloader: true # Indicates if a bootloader should be installed.
      wipe: false # Indicates if the installation disk should be wiped at installation time.

    certSANs:
%{if customize_network ~}
      - ${node_ip_address}
%{ endif ~}
      - ${cluster_endpoint}
    #     - 172.16.0.10
    #     - 192.168.0.10

    # # Used to partition, format and mount additional disks.

    # # MachineDisks list example.
%{ if add_extra_node_disk ~}
    disks:
      - device: /dev/sdb
        partitions:
          - mountpoint: /var/mnt/extra
%{ else ~}

%{ endif ~}

cluster:
    # Provides control plane specific configuration options.
    controlPlane:
        endpoint: https://${cluster_endpoint}:${talos_cluster_endpoint_port} # Endpoint is the canonical controlplane endpoint, which can be an IP address or a DNS hostname.
%{ if type != "worker" ~}
    clusterName: ${kube_cluster_name} # Configures the cluster's name.
    id: ${kube_cluster_id} # Globally unique identifier for this cluster
%{ endif ~}
    # Provides cluster specific network configuration options.
    network:
        dnsDomain: ${kube_dns_domain} # The domain used by Kubernetes DNS.
        # The pod subnet CIDR.
        podSubnets:
            - 10.244.0.0/16
        # The service subnet CIDR.
        serviceSubnets:
            - 10.96.0.0/12

        # The CNI used.
%{if type == "init" && custom_cni ~}
        cni:
          name: none
          urls:
%{ for url in cni_urls ~}
              - ${url}
%{ endfor ~}
%{ else ~}
%{ endif ~}
    token: ${kube_token} # The [bootstrap token](https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/) used to join the cluster.
%{ if type != "worker" ~}
    aescbcEncryptionSecret: ${kube_enc_key} # The key used for the [encryption of secret data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/).
%{ endif ~}
    # The base64 encoded root certificate authority used by Kubernetes.
    ca:
      crt: ${kube_crt}
%{ if type != "worker" ~}
      key: ${kube_key}
%{ else ~}
      key: ""
%{ endif ~}
%{ if type != "worker" ~}
    aggregatorCA:
        crt: ${aggregator_crt}
        key: ${aggregator_key}
    serviceAccount:
        key: ${serviceaccount_key}    
    # API server specific configuration options.
    apiServer:
      image: registry.k8s.io/kube-apiserver:v1.26.1
        # Extra certificate subject alternative names for the API server's certificate.
      certSANs:
        - ${cluster_endpoint}
        - ${hostname}

      disablePodSecurityPolicy: true # Disable PodSecurityPolicy in the API server and default manifests.
      # Configure the API server admission plugins.
      admissionControl:
          - name: PodSecurity # Name is the name of the admission controller.
              # Configuration is an embedded configuration object to be used as the plugin's
            configuration:
              apiVersion: pod-security.admission.config.k8s.io/v1alpha1
              defaults:
                audit: restricted
                audit-version: latest
                enforce: baseline
                enforce-version: latest
                warn: restricted
                warn-version: latest
              exemptions:
                namespaces:
                  - kube-system
                runtimeClasses: []
                usernames: []
              kind: PodSecurityConfiguration
      # Configure the API server audit policy.
      auditPolicy:
        apiVersion: audit.k8s.io/v1
        kind: Policy
        rules:
          - level: Metadata
    # Controller manager server specific configuration options.
    controllerManager:
      image: registry.k8s.io/kube-controller-manager:v1.26.1 # The container image used in the controller manager manifest.
    # Kube-proxy server-specific configuration options
    proxy:
      image: registry.k8s.io/kube-proxy:v1.26.1 # The container image used in the kube-proxy manifest.
      # # Disable kube-proxy deployment on cluster bootstrap.
      # disabled: false
  # Scheduler server specific configuration options.
    scheduler:
        image: registry.k8s.io/kube-scheduler:v1.26.1 

    # Etcd specific configuration options.
    etcd:
      ca:
        crt: ${etcd_crt}
        key: ${etcd_key}

%{ endif }
    # # Core DNS specific configuration options.
    # coreDNS:
    #     image: k8s.gcr.io/coredns:1.7.0 # The `image` field is an override to the default coredns image.

    # # External cloud provider configuration.
    # externalCloudProvider:
    #     enabled: true # Enable external cloud provider.
    #     # A list of urls that point to additional manifests for an external cloud provider.
    #     manifests:
    #         - https://raw.githubusercontent.com/kubernetes/cloud-provider-aws/v1.20.0-alpha.0/manifests/rbac.yaml
    #         - https://raw.githubusercontent.com/kubernetes/cloud-provider-aws/v1.20.0-alpha.0/manifests/aws-cloud-controller-manager-daemonset.yaml

    # # A list of urls that point to additional manifests.
    extraManifests:
      - https://github.com/mologie/talos-vmtoolsd/releases/download/0.3.1/talos-vmtoolsd-0.3.1.yaml

    # # Settings for admin kubeconfig generation.
    # adminKubeconfig:
    #     certLifetime: 1h0m0s # Admin kubeconfig certificate lifetime (default is 1 year).
