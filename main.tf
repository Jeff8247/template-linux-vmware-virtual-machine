locals {
  # Default computer_name to vm_name when not explicitly set.
  computer_name = var.computer_name != null ? var.computer_name : var.vm_name

  # Construct domain join script from variables when linux_domain_join_user is set.
  # Takes precedence over linux_script_text (mutually exclusive).
  linux_script_text = var.linux_domain_join_user != null ? <<-SCRIPT
    #!/bin/bash
    set -e
    dnf install -y realmd sssd sssd-tools adcli krb5-workstation oddjob oddjob-mkhomedir
    realm discover ${var.domain}
    echo "${var.linux_domain_join_password}" | realm join --user=${var.linux_domain_join_user} ${var.domain}
    realm permit --all
    sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
    systemctl enable --now oddjobd
    authselect enable-feature with-mkhomedir
    systemctl restart sssd
  SCRIPT
  : var.linux_script_text
}

check "cluster_host_exclusive" {
  assert {
    condition     = !(var.cluster != null && var.host != null)
    error_message = "cluster and host are mutually exclusive; set only one."
  }
}

check "datastore_exclusive" {
  assert {
    condition     = !(var.datastore != null && var.datastore_cluster != null)
    error_message = "datastore and datastore_cluster are mutually exclusive; set only one."
  }
}

check "domain_join_requires_domain" {
  assert {
    condition     = var.linux_domain_join_user == null || var.domain != null
    error_message = "domain must be set when linux_domain_join_user is specified."
  }
}

check "domain_join_requires_password" {
  assert {
    condition     = var.linux_domain_join_user == null || var.linux_domain_join_password != null
    error_message = "linux_domain_join_password must be set when linux_domain_join_user is specified."
  }
}

check "domain_join_script_exclusive" {
  assert {
    condition     = !(var.linux_domain_join_user != null && var.linux_script_text != null)
    error_message = "linux_domain_join_user and linux_script_text are mutually exclusive; use one or the other."
  }
}

module "vm" {
  source = "github.com/Jeff8247/module-vmware-virtual-machine?ref=v1.0.6"

  # Infrastructure placement
  datacenter        = var.datacenter
  cluster           = var.cluster
  resource_pool     = var.resource_pool
  datastore         = var.datastore
  datastore_cluster = var.datastore_cluster
  host              = var.host

  # VM identity
  vm_name    = var.vm_name
  vm_folder  = var.vm_folder
  annotation = var.annotation
  tags       = var.tags

  # Template
  template_name       = var.template_name
  template_datacenter = var.template_datacenter
  linked_clone        = var.linked_clone

  # CPU
  num_cpus             = var.num_cpus
  num_cores_per_socket = var.num_cores_per_socket
  cpu_hot_add_enabled  = var.cpu_hot_add_enabled
  cpu_reservation      = var.cpu_reservation
  cpu_limit            = var.cpu_limit
  cpu_share_level      = var.cpu_share_level

  # Memory
  memory                 = var.memory
  memory_hot_add_enabled = var.memory_hot_add_enabled
  memory_reservation     = var.memory_reservation
  memory_limit           = var.memory_limit
  memory_share_level     = var.memory_share_level

  # Storage
  disks                 = var.disks
  scsi_type             = var.scsi_type
  scsi_controller_count = var.scsi_controller_count

  # Networking
  network_interfaces = var.network_interfaces
  ip_settings        = var.ip_settings
  ipv4_gateway       = var.ipv4_gateway
  dns_servers        = var.dns_servers
  dns_suffix_list    = var.dns_suffix_list

  # Guest OS - Linux
  guest_id      = var.guest_id
  is_windows    = false
  computer_name = local.computer_name
  domain        = var.domain
  time_zone     = var.time_zone

  # Hardware
  firmware                    = var.firmware
  hardware_version            = var.hardware_version
  nested_hv_enabled           = var.nested_hv_enabled
  enable_disk_uuid            = var.enable_disk_uuid
  vbs_enabled             = var.vbs_enabled
  efi_secure_boot_enabled = var.efi_secure_boot_enabled
  linux_script_text       = local.linux_script_text
  wait_for_guest_net_timeout  = var.wait_for_guest_net_timeout
  wait_for_guest_net_routable = var.wait_for_guest_net_routable
  customize_timeout           = var.customize_timeout

  extra_config = var.extra_config
}
