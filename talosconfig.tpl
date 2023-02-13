context: ${talos_cluster_name}
contexts:
  ${talos_cluster_name}:
    endpoints:
      - ${tf_endpoints}
    nodes:
%{for node in nodes ~}
      - ${node}
%{endfor ~}
    ca: ${tf_talos_ca_crt}
    crt: ${tf_talos_admin_crt}
    key: ${tf_talos_admin_key}
