# Ansible Role: Virtualization

This role prepares a Linux host for QEMU/KVM/Libvirt virtualization.

## Features

- **Package Management**: Installs required virtualization packages (`qemu`, `libvirt`, `virtinst`, etc.).
- **User Permissions**: Automatically adds the running user to the `libvirt` group for passwordless management.
- **Network Provisioning**: Configures the default Libvirt NAT network and ensures it starts on boot.
- **Health Checks**: Verifies CPU hardware virtualization support and Libvirt service status.

## Role Variables

Defined in `defaults/main.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `virtualization_packages` | List | Packages required for KVM/Libvirt |
| `libvirt_group` | `libvirt` | Group for libvirt socket permissions |
| `check_virtualization_support` | `true` | Whether to check for VT-x/AMD-V |
| `libvirt_default_network` | Object | Parameters for the `default` network |

## Usage

This role is typically run as part of the host preparation phase:

```yaml
- hosts: localhost
  roles:
    - role: virtualization
```

## Dependencies

None.
