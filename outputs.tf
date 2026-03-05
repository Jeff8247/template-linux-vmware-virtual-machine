output "vm_name" {
  description = "Name of the deployed virtual machine"
  value       = module.vm.name
}

output "vm_id" {
  description = "Managed object ID of the virtual machine"
  value       = module.vm.id
}

output "default_ip_address" {
  description = "Default IP address of the virtual machine"
  value       = module.vm.default_ip_address
}

output "ip_addresses" {
  description = "All IP addresses reported by VMware Tools"
  value       = module.vm.guest_ip_addresses
}

output "vm_uuid" {
  description = "BIOS UUID of the virtual machine (useful for CMDB and monitoring integration)"
  value       = module.vm.uuid
}

output "power_state" {
  description = "Current power state of the virtual machine"
  value       = module.vm.power_state
}
