# lvm_rhcsa

An Ansible role to configure LVM and manage secondary disks on the RHCSA training node (`rhcsa-node1`).

## Overview

This role covers the full LVM lifecycle — from installing the `lvm2` package through to live-migrating data between physical volumes with `pvmove`. Each step is split into its own task file and can be run independently via the Makefile.

### LVM Architecture

```
┌──────────────────────────────────────────────────────┐
│  rhcsa-node1 VM                                      │
│                                                      │
│  /dev/vdb (10G)          /dev/vdc (10G)              │
│       │                       │                      │
│       ▼                       ▼                      │
│  ┌─────────┐            ┌─────────┐                  │
│  │   PV    │            │   PV    │                  │
│  └────┬────┘            └────┬────┘                  │
│       │                      │                       │
│       ▼                      ▼                       │
│  ┌──────────────────────────────────┐                │
│  │       VG: data_vg                │                │
│  │                                  │                │
│  │  ┌──────────┐  ┌──────────┐     │                │
│  │  │  app_lv  │  │  db_lv   │     │                │
│  │  │   4G     │  │  4G→5G   │     │                │
│  │  └──────────┘  └────┬─────┘     │                │
│  └──────────────────────┼──────────┘                │
│                         │                            │
│                    XFS format                        │
│                    mount → /mnt/database              │
└──────────────────────────────────────────────────────┘
```

## Task Files

Each step lives in its own YAML file under `roles/lvm_rhcsa/tasks/`:

| Task file | Make target | Description |
|---|---|---|
| `install_lvm.yml` | `make lvm_install` | Install the `lvm2` package inside the VM |
| `create_disk.yml` | `make lvm_create_disk` | Create `rhcsa-data1.qcow2` (10G) and attach as `/dev/vdb` |
| `create_pv.yml` | `make lvm_create_pv` | `pvcreate /dev/vdb` — stamp the LVM header |
| `create_vg.yml` | `make lvm_create_vg` | `vgcreate data_vg /dev/vdb` — create the storage pool |
| `create_lv.yml` | `make lvm_create_lv` | Create `app_lv` (4G) and `db_lv` (4G) in `data_vg` |
| `format_mount.yml` | `make lvm_format_mount` | Format `db_lv` with XFS and mount to `/mnt/database` |
| `extend_lv.yml` | `make lvm_extend_lv` | Extend `db_lv` by 1G (4G → 5G) with live filesystem resize |
| `lvm_summary.yml` | `make lvm_summary` | Show JSON summary of all PVs, VGs, LVs, and block devices |
| `configure.yml` | `make lvm_setup` | **Full setup** — runs all of the above in order |
| `cleanup.yml` | `make lvm_clean` | Tear down: unmount, remove LVs, VG, and PV |
| `add_hd.yml` | `make lvm_add_hd` | Create `rhcsa-data2.qcow2` (10G) and attach as `/dev/vdc` |
| `prepare_vdc.yml` | `make lvm_prepare_vdc` | `pvcreate /dev/vdc` + `vgextend data_vg /dev/vdc` |
| `pvmove.yml` | `make lvm_pvmove` | Live-migrate all data from `/dev/vdb` → `/dev/vdc` |

> **Note:** `make lvm_reconfigure` runs `lvm_clean` followed by `lvm_setup` for a full reset.

## Typical Workflows

### Initial Setup (all-in-one)

```bash
make lvm_setup
```

### Step-by-Step Setup

```bash
make lvm_install         # 1. Install lvm2
make lvm_create_disk     # 2. Create & attach vdb
make lvm_create_pv       # 3. Initialize PV
make lvm_create_vg       # 4. Create VG
make lvm_create_lv       # 5. Create LVs
make lvm_format_mount    # 6. Format & mount db_lv
make lvm_extend_lv       # 7. Extend db_lv +1G
make lvm_summary         # 8. Verify everything
```

### Live Migration (pvmove)

Migrate all data from `vdb` to `vdc` with zero downtime:

```bash
make lvm_add_hd          # 1. Create & attach vdc
make lvm_prepare_vdc     # 2. pvcreate + vgextend (add vdc to data_vg)
make lvm_pvmove          # 3. pvmove /dev/vdb /dev/vdc
```

### Clean & Reconfigure

```bash
make lvm_clean           # Tear down LVM (unmount, lvremove, vgremove, pvremove)
make lvm_reconfigure     # Clean + full setup in one command
```

## Commands Reference

### Disk Creation & Attachment (run on host)

```bash
# Create 10GB qcow2 disk images
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/rhcsa-data1.qcow2 10G
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/rhcsa-data2.qcow2 10G

# Attach the disks to the VM
sudo virsh attach-disk rhcsa-node1 \
  --source /var/lib/libvirt/images/rhcsa-data1.qcow2 \
  --target vdb \
  --persistent \
  --driver qemu \
  --subdriver qcow2

sudo virsh attach-disk rhcsa-node1 \
  --source /var/lib/libvirt/images/rhcsa-data2.qcow2 \
  --target vdc \
  --persistent \
  --driver qemu \
  --subdriver qcow2

# Verify disks are attached
sudo virsh domblklist rhcsa-node1
```

### Physical Volume (run inside the VM)

```bash
sudo pvcreate /dev/vdb
sudo pvcreate /dev/vdc          # for the second disk
sudo pvdisplay
```

### Volume Group (run inside the VM)

```bash
sudo vgcreate data_vg /dev/vdb  # create VG with vdb
sudo vgextend data_vg /dev/vdc  # add vdc to existing VG
sudo vgdisplay data_vg
```

### Logical Volume (run inside the VM)

```bash
# Create logical volumes
sudo lvcreate -n app_lv -L 4G data_vg
sudo lvcreate -n db_lv -L 4G data_vg

# Format and mount
sudo mkfs.xfs /dev/mapper/data_vg-db_lv
sudo mkdir -p /mnt/database
sudo mount /dev/mapper/data_vg-db_lv /mnt/database

# Extend LV + filesystem together
sudo lvextend -r -L +1G /dev/mapper/data_vg-db_lv

# Verify
sudo lvdisplay /dev/data_vg/app_lv
sudo lvdisplay /dev/data_vg/db_lv
df -h /mnt/database
```

### Live Migration with pvmove (run inside the VM)

```bash
# Migrate all extents from vdb to vdc (zero downtime)
sudo pvmove /dev/vdb /dev/vdc

# Verify data is now on vdc
sudo pvdisplay
```

## Requirements

- KVM/Libvirt must be installed and running on the host machine.
- `qemu-img` and `virsh` commands must be available and executable by the Ansible user.
- The `rhcsa-node1` virtual machine must exist and be running.

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `lvm_action` | `configure` | Which task file to run (see Task Files table above) |

## Dependencies

None.

## Example Playbook

```yaml
- name: Configure Virtualization Host
  hosts: localhost
  roles:
    - { role: lvm_rhcsa, tags: ["lvm", "setup"] }
```

## License

MIT
