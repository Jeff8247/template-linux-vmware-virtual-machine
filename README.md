# Linux VMware VM — Terraform Template

Terraform template for deploying Linux virtual machines on vSphere. Wraps the [`Jeff8247/module-vmware-virtual-machine`](https://github.com/Jeff8247/module-vmware-virtual-machine) module with Linux-specific defaults, input validation, and sensible out-of-the-box configuration.

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.3, < 2.0` |
| vSphere provider | `~> 2.6` |
| vCenter | 7.0+ recommended |

A Linux VM template with VMware Tools installed must already exist in vCenter and have `open-vm-tools` (or VMware Tools) running to support guest customization.

## Quick Start

```bash
# 1. Copy the example vars file and fill in your values
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars

# 2. Set credentials via environment variables (recommended — avoids storing them in files)
export TF_VAR_vsphere_password="..."

# 3. Initialize and deploy
terraform init
terraform plan
terraform apply
```

## Credentials

Passwords should **not** be stored in `terraform.tfvars`. Use environment variables instead:

```bash
export TF_VAR_vsphere_password="your-vcenter-password"
```

The `.gitignore` in this repo excludes `terraform.tfvars` and `*.auto.tfvars` to prevent accidental commits of credentials.

## Examples

### Minimal — DHCP, single NIC

```hcl
vsphere_server = "vcenter.example.com"          # hostname or IP only — no https://
vsphere_user   = "administrator@vsphere.local"  # UPN format; DOMAIN\user also works
datacenter     = "dc01"                         # exact name as shown in vCenter inventory
cluster        = "cluster01"                    # exact name as shown in vCenter inventory
datastore      = "datastore01"                  # exact name as shown in vCenter inventory
vm_name        = "linux-vm-01"
template_name  = "ubuntu-22.04-template"
guest_id       = "ubuntu64Guest"

network_interfaces = [{ network_name = "VM Network" }]
```

### Static IP

```hcl
network_interfaces = [{ network_name = "VM Network" }]

ip_settings = [
  {
    ipv4_address = "192.168.1.100"
    ipv4_netmask = 24
  }
]

ipv4_gateway    = "192.168.1.1"
dns_servers     = ["192.168.1.10", "192.168.1.11"]
dns_suffix_list = ["corp.example.com"]
```

### Multiple disks

```hcl
disks = [
  {
    label            = "disk0"
    size             = 50
    unit_number      = 0
    thin_provisioned = true
  },
  {
    label            = "disk1"
    size             = 200
    unit_number      = 1
    thin_provisioned = true
  }
]
```

### EFI firmware with custom timezone

```hcl
firmware  = "efi"
time_zone = "America/New_York"
```

## Variable Reference

### vCenter Connection

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vsphere_server` | `string` | required | vCenter server hostname or IP |
| `vsphere_user` | `string` | required | vCenter username |
| `vsphere_password` | `string` | required | vCenter password (sensitive) |
| `vsphere_allow_unverified_ssl` | `bool` | `false` | Skip TLS certificate verification |

**`vsphere_server`** — hostname or IP address only, no protocol or port (e.g. `vcenter.example.com`, not `https://vcenter.example.com`).

**`vsphere_user`** — UPN format (`user@domain`, e.g. `administrator@vsphere.local`) or `DOMAIN\user` format.

### Infrastructure Placement

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `datacenter` | `string` | required | vSphere datacenter name |
| `cluster` | `string` | `null` | vSphere cluster name (mutually exclusive with `host`) |
| `host` | `string` | `null` | vSphere host name (mutually exclusive with `cluster`) |
| `resource_pool` | `string` | `null` | Resource pool name; `null` uses the cluster/host root pool |
| `datastore` | `string` | `null` | Datastore name (mutually exclusive with `datastore_cluster`) |
| `datastore_cluster` | `string` | `null` | Datastore cluster name (mutually exclusive with `datastore`) |

All inventory names (`datacenter`, `cluster`, `host`, `datastore`, `datastore_cluster`, `resource_pool`) must match **exactly** as they appear in the vCenter inventory — they are case-sensitive. Find them in the vSphere Client under the Hosts & Clusters and Storage views.

Set exactly one of `cluster` or `host`, and exactly one of `datastore` or `datastore_cluster`. The template enforces this with `check` blocks that fail at plan time if both are set.

### VM Identity

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vm_name` | `string` | required | VM name in vSphere inventory (max 80 chars) |
| `vm_folder` | `string` | `null` | vSphere folder path, e.g. `"VMs/Linux"` |
| `annotation` | `string` | `null` | VM notes / annotation |
| `tags` | `map(string)` | `{}` | vSphere tags as `{ category = "tag-name" }`. The tag category and tag value must already exist in vCenter. |

#### Tagging Example

Tags are key/value pairs where the key is the **tag category** name and the value is the **tag name**, both as they appear in vCenter. Categories and tags must be pre-created in vCenter before deployment.

```hcl
tags = {
  "Environment" = "Production"   # e.g. Production, Development, Test
  "Owner"       = "platform-team"
  "CostCentre"  = "CC-1234"
  "Application" = "my-app"
}
```

> **Tip:** Enforce mandatory tags by creating the required tag categories in vCenter with the **Cardinality** set to `One tag per object` — this prevents a VM from having multiple values for the same category.

### Template

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `template_name` | `string` | required | vSphere template to clone |
| `template_datacenter` | `string` | `null` | Datacenter where the template lives (if different from target) |
| `linked_clone` | `bool` | `false` | Create a linked clone instead of a full clone |

### CPU

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `num_cpus` | `number` | `2` | Total vCPU count |
| `num_cores_per_socket` | `number` | `null` | Cores per socket — defaults to `num_cpus` (single socket) |
| `cpu_hot_add_enabled` | `bool` | `false` | Allow CPU hot-add |
| `cpu_reservation` | `number` | `0` | CPU reservation in MHz |
| `cpu_limit` | `number` | `-1` | CPU limit in MHz (`-1` = unlimited) |
| `cpu_share_level` | `string` | `"normal"` | Share level: `low`, `normal`, `high`, or `custom` |

### Memory

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `memory` | `number` | `4096` | Memory in MB — must be a multiple of 4 |
| `memory_hot_add_enabled` | `bool` | `false` | Allow memory hot-add |
| `memory_reservation` | `number` | `0` | Memory reservation in MB |
| `memory_limit` | `number` | `-1` | Memory limit in MB (`-1` = unlimited) |
| `memory_share_level` | `string` | `"normal"` | Share level: `low`, `normal`, `high`, or `custom` |

### Storage

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `disks` | `list(object)` | 50 GB thin disk | List of disk configs — see [Disk Object](#disk-object) |
| `scsi_type` | `string` | `"pvscsi"` | SCSI controller type: `pvscsi` or `lsilogicsas` |
| `scsi_controller_count` | `number` | `1` | Number of SCSI controllers |

#### Disk Object

```hcl
{
  label            = "disk0"          # required
  size             = 50               # required, in GB
  unit_number      = 0                # optional, SCSI unit number
  thin_provisioned = true             # optional, default true
  eagerly_scrub    = false            # optional, default false
  datastore        = null             # optional, override per-disk datastore
}
```

### Networking

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `network_interfaces` | `list(object)` | required | At least one NIC — see [Network Interface Object](#network-interface-object) |
| `ip_settings` | `list(object)` | `[]` | Static IP per NIC — leave empty for DHCP |
| `ipv4_gateway` | `string` | `null` | Default IPv4 gateway |
| `dns_servers` | `list(string)` | `[]` | DNS server addresses |
| `dns_suffix_list` | `list(string)` | `[]` | DNS search suffixes |

#### Network Interface Object

```hcl
{
  network_name = "VM Network"   # required — port group or DVS port group name
  adapter_type = "vmxnet3"      # optional — vmxnet3 (default), e1000e, or e1000
}
```

#### IP Settings Object

```hcl
{
  ipv4_address = "192.168.1.100"   # required
  ipv4_netmask = 24                # required — prefix length, 1–32
}
```

One entry per NIC, in the same order as `network_interfaces`.

### Guest OS — Linux

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `guest_id` | `string` | required | vSphere guest OS ID, e.g. `ubuntu64Guest` |
| `computer_name` | `string` | `null` | VM hostname. Defaults to `vm_name` |
| `domain` | `string` | `null` | DNS search domain suffix applied to the guest OS (e.g. `corp.example.com`). **This is not an AD domain join** — see [Active Directory Domain Join](#active-directory-domain-join) below. |
| `time_zone` | `string` | `"UTC"` | Linux timezone string, e.g. `America/New_York` |

Common `guest_id` values:

| OS | `guest_id` |
|----|-----------|
| Ubuntu 24.04 | `ubuntu64Guest` |
| Ubuntu 22.04 | `ubuntu64Guest` |
| RHEL 9 | `rhel9_64Guest` |
| RHEL 8 | `rhel8_64Guest` |
| Debian 12 | `debian12_64Guest` |
| Rocky Linux 9 | `rockylinux_64Guest` |
| AlmaLinux 9 | `almalinux_64Guest` |
| CentOS 8 | `centos8_64Guest` |

Common `time_zone` values:

| Timezone | String |
|----------|--------|
| UTC | `UTC` |
| Eastern | `America/New_York` |
| Central | `America/Chicago` |
| Mountain | `America/Denver` |
| Pacific | `America/Los_Angeles` |
| London | `Europe/London` |
| Central Europe | `Europe/Berlin` |

Full list: [IANA Time Zone Database](https://www.iana.org/time-zones)

### Linux Script Example

`linux_script_text` runs as root during guest customization, after the hostname and network have been applied. Useful for first-boot configuration that doesn't warrant a full configuration management tool.

```hcl
linux_script_text = <<-EOF
  #!/bin/bash
  set -e

  # --- NTP (point at internal server instead of pool.ntp.org) ---
  sed -i 's/^pool .*//' /etc/chrony.conf
  echo "server ntp.corp.example.com iburst" >> /etc/chrony.conf
  systemctl restart chronyd

  # --- SSH hardening ---
  sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
  sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
  systemctl restart sshd

  # --- Disable firewalld (if managed by a perimeter firewall) ---
  systemctl disable --now firewalld

  # --- Install base tooling ---
  dnf install -y vim curl wget git net-tools open-vm-tools

  # --- Apply all updates ---
  dnf update -y

  # --- Deploy an authorized_keys for the ops team ---
  mkdir -p /home/svc-ops/.ssh
  echo "ssh-ed25519 AAAA... ops-team-key" >> /home/svc-ops/.ssh/authorized_keys
  chmod 700 /home/svc-ops/.ssh
  chmod 600 /home/svc-ops/.ssh/authorized_keys
  chown -R svc-ops:svc-ops /home/svc-ops/.ssh

  # --- Register with Red Hat Satellite / Subscription Manager ---
  subscription-manager register --org="MyOrg" --activationkey="rhel9-standard"

  # --- Install and enable Puppet agent ---
  rpm -Uvh https://yum.puppet.com/puppet8-release-el-9.noarch.rpm
  dnf install -y puppet-agent
  systemctl enable --now puppet

  # --- Set DNS resolver explicitly ---
  echo "DNS=192.168.1.10 192.168.1.11" >> /etc/systemd/resolved.conf
  systemctl restart systemd-resolved

  # --- Disable IPv6 (common in locked-down environments) ---
  echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.d/99-disable-ipv6.conf
  sysctl --system
EOF
```

> **Note:** The script runs as root in the context of open-vm-tools during customization. Keep it lightweight — long-running tasks (large package installs, reboots) can cause the customization timeout to be exceeded. For heavy provisioning use a configuration management tool (Ansible, Puppet) triggered post-boot instead. Remove or comment out any blocks that do not apply to your environment.

### Provisioning Without Domain Join

Leave `linux_domain_join_user` and `linux_script_text` unset (both default to `null`) and no script runs during customization. The VM is provisioned with its hostname, timezone, and network settings only. Use this path for VMs that will be managed post-boot by a configuration management tool, or that simply don't require domain membership.

### Active Directory Domain Join

Unlike Windows, vSphere guest customization does **not** perform an AD domain join for Linux VMs. The `domain` variable sets only the DNS search suffix. To join a Linux VM to Active Directory set `linux_domain_join_user` in `terraform.tfvars` and pass the password via environment variable — the template will construct and execute the `realm join` script automatically during customization using `realmd` and `sssd`.

| Variable | Where to set | Description |
|---|---|---|
| `domain` | `terraform.tfvars` | AD domain to discover and join (e.g. `corp.example.com`) |
| `linux_domain_join_user` | `terraform.tfvars` | AD user account with machine join permissions |
| `linux_domain_join_password` | `TF_VAR_linux_domain_join_password` env var | Join account password — never store in tfvars |

#### terraform.tfvars

```hcl
domain                 = "corp.example.com"
linux_domain_join_user = "svc-domain-join"
```

#### Environment variable

```bash
export TF_VAR_linux_domain_join_password="your-domain-join-password"
```

The template will automatically construct and run the following script during customization, with `domain`, `linux_domain_join_user`, and `linux_domain_join_password` interpolated from your variables. The script detects the package manager at runtime and works on both RHEL-family and Debian/Ubuntu guests:

```bash
#!/bin/bash
set -e
if command -v dnf >/dev/null 2>&1; then
  dnf install -y realmd sssd sssd-tools adcli krb5-workstation oddjob oddjob-mkhomedir
elif command -v apt-get >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y realmd sssd adcli krb5-user oddjob oddjob-mkhomedir packagekit
else
  echo "Unsupported package manager" >&2; exit 1
fi
realm discover ${var.domain}
printf '%s\n' "${var.linux_domain_join_password}" | realm join --user="${var.linux_domain_join_user}" "${var.domain}"
realm permit --all
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
systemctl enable --now oddjobd
authselect enable-feature with-mkhomedir
systemctl restart sssd
```

> **Note:** `linux_domain_join_user` and `linux_script_text` are mutually exclusive — the template will raise an error at plan time if both are set.

> **State warning:** The constructed script (including the interpolated password) is stored in Terraform state and redacted from plan/apply terminal output. For environments with strict secrets management, consider leaving domain join to a configuration management tool (Ansible, Puppet) triggered post-boot instead.

### Hardware

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `firmware` | `string` | `"bios"` | Firmware type: `bios` or `efi` |
| `hardware_version` | `number` | `null` | VMware hardware version; `null` keeps the template version |
| `nested_hv_enabled` | `bool` | `false` | Enable nested hardware virtualization |
| `enable_disk_uuid` | `bool` | `true` | Expose disk UUIDs to the guest OS |
| `vbs_enabled` | `bool` | `false` | Enable Virtualization-Based Security (requires EFI) |
| `efi_secure_boot_enabled` | `bool` | `false` | Enable EFI Secure Boot (requires firmware = efi) |
| `linux_script_text` | `string` | `null` | Inline shell script to run during guest customization. Mutually exclusive with `linux_domain_join_user`. See example below. |
| `linux_domain_join_user` | `string` | `null` | AD user for domain join. Requires `domain` and `linux_domain_join_password`. Mutually exclusive with `linux_script_text`. |
| `linux_domain_join_password` | `string` | `null` | Domain join password (sensitive) — set via `TF_VAR_linux_domain_join_password` |
| `wait_for_guest_net_timeout` | `number` | `5` | Minutes to wait for guest networking (`0` disables) |
| `wait_for_guest_net_routable` | `bool` | `true` | Require a routable IP before marking VM ready |
| `customize_timeout` | `number` | `30` | Minutes to wait for guest customization to complete |
| `extra_config` | `map(string)` | `{}` | Additional VMX key/value pairs |

## Outputs

| Output | Description |
|--------|-------------|
| `vm_name` | Name of the deployed virtual machine |
| `vm_id` | Managed object ID (MOID) of the VM |
| `vm_uuid` | BIOS UUID — useful for CMDB and monitoring integration |
| `power_state` | Current power state of the VM |
| `default_ip_address` | Primary IP address as reported by VMware Tools |
| `ip_addresses` | All IP addresses reported by VMware Tools |

## File Structure

```
.
├── main.tf                    # Module call, locals, mutual-exclusivity checks
├── variables.tf               # All input variables with validation
├── outputs.tf                 # Outputs exposed after deployment
├── versions.tf                # Terraform and provider version constraints
├── terraform.tfvars.example   # Annotated example — copy to terraform.tfvars
└── .gitignore                 # Excludes state, .terraform/, and tfvars files
```

## Security Notes

- `vsphere_password` is marked `sensitive = true` and will not appear in plan/apply output.
- `terraform.tfvars` is excluded by `.gitignore`. Never commit credentials.
- `vsphere_allow_unverified_ssl` defaults to `false`. Only set to `true` in non-production lab environments.
- Terraform state (`terraform.tfstate`) contains all resource attributes including sensitive values. Store state in a secured remote backend (e.g. S3 with encryption, Terraform Cloud) for any shared or production use. See `versions.tf` for where to add a backend block.
