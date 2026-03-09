# vCenter connection
variable "vsphere_server" {
  description = "vCenter server hostname or IP address"
  type        = string
}

variable "vsphere_user" {
  description = "vCenter username"
  type        = string
}

variable "vsphere_password" {
  description = "vCenter password"
  type        = string
  sensitive   = true
}

variable "vsphere_allow_unverified_ssl" {
  description = "Allow unverified SSL certificates when connecting to vCenter"
  type        = bool
  default     = false
}

# Infrastructure placement
variable "datacenter" {
  description = "vSphere datacenter name"
  type        = string
}

variable "cluster" {
  description = "vSphere cluster name (mutually exclusive with host)"
  type        = string
  default     = null
}

variable "resource_pool" {
  description = "vSphere resource pool name"
  type        = string
  default     = null
}

variable "datastore" {
  description = "vSphere datastore name (mutually exclusive with datastore_cluster)"
  type        = string
  default     = null
}

variable "datastore_cluster" {
  description = "vSphere datastore cluster name (mutually exclusive with datastore)"
  type        = string
  default     = null
}

variable "host" {
  description = "vSphere host name (mutually exclusive with cluster)"
  type        = string
  default     = null
}

# VM identity
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string

  validation {
    condition     = length(var.vm_name) <= 80
    error_message = "vm_name must be 80 characters or fewer (vSphere limit)."
  }
}

variable "vm_folder" {
  description = "vSphere folder path to place the VM in"
  type        = string
  default     = null
}

variable "annotation" {
  description = "VM annotation / notes"
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of vSphere tag category to tag name to apply to the VM"
  type        = map(string)
  default     = {}
}

# Template
variable "template_name" {
  description = "Name of the vSphere template to clone"
  type        = string
}

variable "template_datacenter" {
  description = "Datacenter where the template resides (if different from target datacenter)"
  type        = string
  default     = null
}

variable "linked_clone" {
  description = "Create a linked clone instead of a full clone"
  type        = bool
  default     = false
}

# CPU
variable "num_cpus" {
  description = "Total number of vCPUs"
  type        = number
  default     = 2
}

variable "num_cores_per_socket" {
  description = "Number of cores per vCPU socket"
  type        = number
  default     = 1
}

variable "cpu_hot_add_enabled" {
  description = "Allow CPUs to be added while the VM is running"
  type        = bool
  default     = false
}

variable "cpu_reservation" {
  description = "CPU reservation in MHz (0 = no reservation)"
  type        = number
  default     = 0
}

variable "cpu_limit" {
  description = "CPU limit in MHz (-1 = no limit)"
  type        = number
  default     = -1
}

variable "cpu_share_level" {
  description = "CPU share allocation level (low, normal, high, or custom)"
  type        = string
  default     = "normal"

  validation {
    condition     = contains(["low", "normal", "high", "custom"], var.cpu_share_level)
    error_message = "cpu_share_level must be one of: low, normal, high, custom."
  }
}

# Memory
variable "memory" {
  description = "Memory size in MB (must be a multiple of 4)"
  type        = number
  default     = 4096

  validation {
    condition     = var.memory % 4 == 0
    error_message = "memory must be a multiple of 4 MB."
  }
}

variable "memory_hot_add_enabled" {
  description = "Allow memory to be added while the VM is running"
  type        = bool
  default     = false
}

variable "memory_reservation" {
  description = "Memory reservation in MB (0 = no reservation)"
  type        = number
  default     = 0
}

variable "memory_limit" {
  description = "Memory limit in MB (-1 = no limit)"
  type        = number
  default     = -1
}

variable "memory_share_level" {
  description = "Memory share allocation level (low, normal, high, or custom)"
  type        = string
  default     = "normal"

  validation {
    condition     = contains(["low", "normal", "high", "custom"], var.memory_share_level)
    error_message = "memory_share_level must be one of: low, normal, high, custom."
  }
}

# Storage
variable "disks" {
  description = "List of disk configurations"
  type = list(object({
    label            = string
    size             = number
    unit_number      = optional(number)
    thin_provisioned = optional(bool, true)
    eagerly_scrub    = optional(bool, false)
    datastore        = optional(string)
  }))
  default = [
    {
      label            = "disk0"
      size             = 50
      unit_number      = 0
      thin_provisioned = true
      eagerly_scrub    = false
    }
  ]

  validation {
    condition     = length(var.disks) == length(distinct([for d in var.disks : d.unit_number]))
    error_message = "Each disk must have a unique unit_number."
  }

  validation {
    condition     = length(var.disks) == length(distinct([for d in var.disks : d.label]))
    error_message = "Each disk must have a unique label."
  }
}

variable "scsi_type" {
  description = "SCSI controller type (pvscsi or lsilogicsas)"
  type        = string
  default     = "pvscsi"

  validation {
    condition     = contains(["pvscsi", "lsilogicsas"], var.scsi_type)
    error_message = "scsi_type must be one of: pvscsi, lsilogicsas."
  }
}

variable "scsi_controller_count" {
  description = "Number of SCSI controllers"
  type        = number
  default     = 1
}

# Networking
variable "network_interfaces" {
  description = "List of network interface configurations"
  type = list(object({
    network_name = string
    adapter_type = optional(string, "vmxnet3")
  }))

  validation {
    condition     = length(var.network_interfaces) >= 1
    error_message = "At least one network interface must be defined."
  }

  validation {
    condition = alltrue([
      for ni in var.network_interfaces :
      contains(["vmxnet3", "e1000e", "e1000"], ni.adapter_type)
    ])
    error_message = "adapter_type must be one of: vmxnet3, e1000e, e1000."
  }
}

variable "ip_settings" {
  description = "List of static IP settings per network interface (leave empty for DHCP)"
  type = list(object({
    ipv4_address = string
    ipv4_netmask = number
  }))
  default = []

  validation {
    condition = alltrue([
      for s in var.ip_settings : s.ipv4_netmask >= 1 && s.ipv4_netmask <= 32
    ])
    error_message = "ipv4_netmask must be between 1 and 32."
  }
}

variable "ipv4_gateway" {
  description = "Default IPv4 gateway"
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "List of DNS server IP addresses"
  type        = list(string)
  default     = []
}

variable "dns_suffix_list" {
  description = "List of DNS search suffixes"
  type        = list(string)
  default     = []
}

# Guest OS - Linux
variable "guest_id" {
  description = "vSphere guest OS identifier (e.g. ubuntu64Guest, rhel9_64Guest, debian12_64Guest)"
  type        = string
}

variable "computer_name" {
  description = "Hostname for the VM. Defaults to vm_name if not set."
  type        = string
  default     = null
}

variable "domain" {
  description = "DNS domain for the VM (used in guest customization)"
  type        = string
  default     = null
}

variable "time_zone" {
  description = "Linux timezone string (e.g. UTC, America/New_York, Europe/London)"
  type        = string
  default     = "UTC"
}

# Hardware
variable "firmware" {
  description = "Firmware type (bios or efi)"
  type        = string
  default     = "bios"

  validation {
    condition     = contains(["bios", "efi"], var.firmware)
    error_message = "firmware must be one of: bios, efi."
  }
}

variable "hardware_version" {
  description = "VMware hardware version (null = use template version)"
  type        = number
  default     = null
}

variable "nested_hv_enabled" {
  description = "Enable nested hardware virtualization"
  type        = bool
  default     = false
}

variable "enable_disk_uuid" {
  description = "Expose disk UUIDs to the guest OS"
  type        = bool
  default     = true
}

variable "vbs_enabled" {
  description = "Enable Virtualization-Based Security (requires EFI firmware)"
  type        = bool
  default     = false
}

variable "wait_for_guest_net_timeout" {
  description = "Minutes to wait for guest networking before timing out (0 to disable)"
  type        = number
  default     = 5
}

variable "wait_for_guest_net_routable" {
  description = "Require a routable IP before considering the VM ready"
  type        = bool
  default     = true
}

variable "customize_timeout" {
  description = "Minutes to wait for guest customization to complete"
  type        = number
  default     = 30
}

variable "extra_config" {
  description = "Additional VMX key/value pairs to set on the VM"
  type        = map(string)
  default     = {}
}
