# Ansible Automation for RHCSA Prep: AlmaLinux 9 on KVM/libvirt

This repository provides a complete automated lab environment for RHCSA (Red Hat Certified System Administrator) EX200 exam preparation. It provisions and manages AlmaLinux 9 virtual machines using Libvirt/KVM, ensuring consistent, repeatable deployments for your study sessions.

## RHCSA Exam Objectives Covered

This lab environment helps you practice the following RHCSA exam objectives:

- **Configure Network Storage (NFS)**: Set up and configure NFS exports and client mounts
- **Configure Local Repositories**: Create and manage DNF/YUM repositories
- **Manage Firewall Rules**: Configure firewalld for various services
- **Manage SELinux**: Understand and configure SELinux contexts and policies
- **Configure System Services**: Manage systemd services and targets
- **Configure Automated Storage**: Practice with LVM and storage management
- **Container Operations**: Basic container management with Podman
- **User and Group Management**: Create and manage users, groups, and permissions
- **Schedule Tasks**: Configure cron and at jobs
- **Configure Time Synchronization**: Manage chrony/time services

## Lab Topology

The lab consists of two VMs connected via libvirt's default NAT network (192.168.122.0/24):

- **rhcsa-node1** (Exam Target): Primary practice environment for LVM, SELinux, firewalld, boot targets, container operations with Podman, user management, and system administration tasks.
- **repo-srv** (Support Node): Provides network services including NFS exports and a local DNF repository for practicing autofs, package installation, and network storage configuration.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Libvirt Host (KVM)                        │
│                  192.168.122.0/24 Network                    │
├──────────────────────┬──────────────────────────────────────┤
│                      │                                      │
│  ┌──────────────────┴──────────────────┐                   │
│  │            rhcsa-node1               │                   │
│  │  - 2 vCPUs, 2GB RAM, 20GB Disk      │                   │
│  │  - AlmaLinux 9 GenericCloud         │                   │
│  │  - Primary exam practice target     │                   │
│  └─────────────────────────────────────┘                   │
│                      │                                      │
│  ┌──────────────────┴──────────────────┐                   │
│  │            repo-srv                  │                   │
│  │  - 1 vCPU, 1GB RAM, 25GB Disk       │                   │
│  │  - AlmaLinux 9 Minimal ISO          │                   │
│  │  - NFS Server + DNF Repository      │                   │
│  └─────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

## Virtual Machines

| VM Name       | Operating System         | Installation Method | VCPUs | RAM   | Disk  | Purpose                          |
|---------------|--------------------------|---------------------|-------|-------|-------|----------------------------------|
| `rhcsa-node1` | AlmaLinux 9 GenericCloud | Cloud-Init Import   | 2     | 2048M | 20G   | Primary exam practice target     |
| `repo-srv`    | AlmaLinux 9 Minimal ISO  | ISO Installation    | 1     | 1024M | 25G   | NFS server + DNF repository      |

**Note:**
- VMs obtain dynamic IPs from the libvirt default network (192.168.122.0/24)
- The `inventory/hosts.yml` file is auto-generated after VM creation with actual IPs
- Both VMs are configured with `root` password set to `redhat` for fallback access
- SSH key-based authentication is configured for passwordless access

## Quick Start

### Prerequisites

- Linux host with KVM/Libvirt support
- Ansible installed on the host
- Sudo access for installing packages and managing libvirt
- AlmaLinux 9 GenericCloud image (auto-downloaded if missing)
- AlmaLinux 9 Minimal ISO (auto-downloaded if missing)

### Initial Setup

1. **Configure virtualization on your host** (installs KVM/QEMU and adds you to libvirt group):
```bash
make configure_virtualization
```

2. **Create all VMs** (or create individual VMs as needed):
```bash
make create_vms            # Creates both rhcsa-node1 and repo-srv
make create_rhcsa_node1    # Creates only rhcsa-node1
make create_repo_srv       # Creates only repo-srv
```

3. **Generate inventory** with actual VM IPs (VMs must be running):
```bash
# Check VM status and obtain IPs
make vm_status
# Update inventory/hosts.yml with the actual IPs shown
```

4. **Provision users** on running VMs (creates sysadmin user with sudo access):
```bash
make create_users
```

### VM Management Commands

```bash
make vm_status                 # Check the running state of the VMs
make workspace                 # Show the disk usage of the VM libvirt images
make clean VM_NAME=<vm-name>   # Destroy and undefine a specific VM
make clean_all                 # Remove all VM images and workspace
```

### Service Setup Commands

```bash
make nfs_setup                 # Configure NFS server on repo-srv
make dnf_repo_setup            # Configure DNF repository on repo-srv
make autofs_setup              # Configure autofs on rhcsa-node1
```

## Accessing the VMs

### SSH Access

After VM creation, obtain the actual IP addresses:
```bash
virsh domifaddr rhcsa-node1
virsh domifaddr repo-srv
```

Then update `inventory/hosts.yml` with the actual IPs and access via SSH:
```bash
ssh root@<rhcsa-node1-ip>
ssh almalinux@<rhcsa-node1-ip>
```

**Fallback Access:**
- If SSH key authentication fails, use password authentication
- Password for both `root` and `almalinux` users: `redhat`
- Console access: `virsh console <vm-name>`

**After User Provisioning:**
Once you run `make create_users`, you can also login via the `sysadmin` administrator user:
```bash
ssh sysadmin@<vm-ip>
```

## Repository Structure

```
sysadmin/
├── Makefile                          # Entry point for all automation commands
├── ansible.cfg                       # Ansible configuration
├── inventory/
│   └── hosts.yml                     # Dynamic inventory with VM connection details
├── playbooks/
│   ├── create_vms.yml                # Master playbook for VM creation
│   ├── create_rhcsa_node1.yml        # Playbook for rhcsa-node1 VM
│   ├── create_repo_srv.yml           # Playbook for repo-srv VM
│   └── configure.yml                 # Master configuration playbook
├── roles/
│   ├── virtualization/               # KVM/Libvirt host preparation
│   ├── vm-manager/                   # VM lifecycle management
│   └── users/                        # User provisioning across VMs
├── docs/
│   └── nfs-dnf-repo.md               # Detailed NFS and DNF repository guide
└── scripts/
    └── ip_cli.sh                     # Utility for mapping veth interfaces to containers
```

## Study Guides and Documentation

### Available Documentation

- **[NFS and DNF Repository Setup](docs/nfs-dnf-repo.md)**: Comprehensive guide for configuring NFS exports and local DNF repositories, including exam strategies, troubleshooting tips, and real-world applications.

### Recommended Study Path

1. **Foundation Skills** (Week 1-2)
   - Practice user and group management on rhcsa-node1
   - Configure file permissions and ownership
   - Set up cron jobs and scheduled tasks
   - Practice basic file operations and text processing

2. **System Administration** (Week 3-4)
   - Configure systemd services and targets
   - Manage firewalld rules and zones
   - Understand and configure SELinux
   - Practice with log file analysis and journalctl

3. **Storage Management** (Week 5-6)
   - Create and manage LVM volumes
   - Configure filesystems and mount points
   - Set up NFS exports (using repo-srv)
   - Configure autofs for automatic mounting

4. **Network Services** (Week 7-8)
   - Set up local DNF repositories (using repo-srv)
   - Configure network interfaces and routing
   - Practice with time synchronization (chrony)
   - Configure container operations with Podman

5. **Exam Simulation** (Week 9-10)
   - Timed practice sessions
   - Multi-objective scenarios
   - Troubleshooting exercises
   - Mock exam conditions

## Troubleshooting

### VM Creation Issues

**Problem:** VM fails to start with "no bootable device"
- **Solution:** Ensure the base image exists at `/var/lib/libvirt/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2`
- **Solution:** Verify the disk overlay was created successfully

**Problem:** VM boots but no network connectivity
- **Solution:** Check libvirt default network is running: `virsh net-info default`
- **Solution:** Restart the network: `virsh net-destroy default && virsh net-start default`

### SSH Access Issues

**Problem:** Permission denied (publickey)
- **Solution:** Verify your SSH public key is in the cloud-init user-data
- **Solution:** Use password authentication as fallback: `ssh root@<ip>` (password: redhat)

**Problem:** Connection refused
- **Solution:** Verify VM is running: `virsh list --all`
- **Solution:** Check VM has obtained IP: `virsh domifaddr <vm-name>`

### Service Configuration Issues

**Problem:** NFS mount fails
- **Solution:** Verify NFS server is running: `systemctl status nfs-server` on repo-srv
- **Solution:** Check firewall rules: `firewall-cmd --list-all`
- **Solution:** Test export visibility: `showmount -e <repo-srv-ip>`

**Problem:** DNF repository not accessible
- **Solution:** Verify httpd is running: `systemctl status httpd` on repo-srv
- **Solution:** Check SELinux contexts: `ls -Z /var/www/html`
- **Solution:** Test HTTP access: `curl http://<repo-srv-ip>/repos/custom/`

## Exam Tips

### Time Management

The RHCSA exam is 3 hours long. Budget your time strategically:
- **Easy tasks (5-10 min each)**: User creation, file permissions, cron jobs
- **Medium tasks (10-15 min each)**: Service configuration, firewall rules, SELinux
- **Complex tasks (20-30 min each)**: LVM configuration, NFS/DNF setup, troubleshooting

### Common Mistakes to Avoid

1. **Not verifying your work**: Always test your configurations before moving on
2. **Ignoring SELinux**: Many failures are due to SELinux contexts, not configuration errors
3. **Forgetting firewall rules**: Services won't be accessible without proper firewalld configuration
4. **Not reading the question carefully**: Pay attention to specific requirements (e.g., "persistent" vs "temporary")
5. **Skipping verification commands**: Use `systemctl status`, `firewall-cmd --list-all`, etc.

### Essential Commands to Memorize

```bash
# System Information
hostnamectl                    # System identity
timedatectl                    # Time and date settings
systemctl list-units --all    # All systemd units
systemctl get-default         # Default target

# User Management
useradd -m -G wheel user      # Create user with wheel group
passwd user                    # Set password
id user                       # User/group information

# File Permissions
chmod 755 file                 # Set permissions
chown user:group file         # Set ownership
restorecon -Rv /path          # Fix SELinux contexts

# Firewall
firewall-cmd --list-all       # Show all rules
firewall-cmd --add-service=http --permanent
firewall-cmd --reload

# LVM
pvcreate /dev/sdb             # Create physical volume
vgcreate vgname /dev/sdb      # Create volume group
lvcreate -L 10G -n lvname vgname  # Create logical volume
lvextend -L +5G /dev/vgname/lvname  # Extend logical volume
resize2fs /dev/vgname/lvname   # Resize filesystem

# NFS
exportfs -rv                   # Reload exports
showmount -e server           # Show exports
mount -t nfs server:/export /mnt  # Mount NFS

# DNF/YUM
dnf repolist                   # List repositories
dnf install package            # Install package
dnf provides /path/to/file     # Find package providing file
```

## Contributing

This is a personal study project, but suggestions and improvements are welcome. Areas for enhancement:
- Additional service configuration playbooks
- More comprehensive documentation
- Additional exam scenario playbooks
- Automated testing/validation

## License

This project is provided as-is for educational purposes. AlmaLinux and Red Hat are trademarks of their respective owners.

## Resources

- [Red Hat Certified System Administrator (RHCSA) Exam](https://www.redhat.com/en/services/certification/rhcsa)
- [AlmaLinux Documentation](https://wiki.almalinux.org/)
- [Libvirt Documentation](https://libvirt.org/docs.html)
- [Ansible Documentation](https://docs.ansible.com/)
