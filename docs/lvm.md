# lvm_rhcsa

An Ansible role to configure LVM and add secondary disks to the RHCSA training nodes (e.g., `rhcsa-node1`).

## Description

This role performs the following tasks to set up Logical Volume Management (LVM):

1. **Install lvm2**: Installs the `lvm2` package on the target VM.
2. **Create Disk Images**: Creates new 10GB qcow2 disk images (`rhcsa-data1.qcow2` and `rhcsa-data2.qcow2`) in the libvirt images directory.
3. **Attach Disks**: Attaches the new disks to the `rhcsa-node1` VM as the `vdb` and `vdc` block devices.
4. **Verify Attachment**: Lists the block devices for `rhcsa-node1` to confirm the disk is attached.
5. **Create Physical Volume (PV)**: Initializes `/dev/vdb` as a physical volume.
6. **Verify PV**: Displays physical volume details to confirm creation.
7. **Create Volume Group (VG)**: Creates a volume group named `data_vg` from the physical volume.
8. **Verify VG**: Displays volume group details to confirm creation.
9. **Create Logical Volume (LV)**: Creates a 4GB logical volume named `app_lv` within `data_vg`.
10. **Verify LV**: Displays logical volume details to confirm creation.

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

# Verify the disk is attached
sudo virsh domblklist rhcsa-node1
```

### Physical Volume (run inside the VM)

```bash
# Create a physical volume on /dev/vdb
sudo pvcreate /dev/vdb

# Verify the physical volume
sudo pvdisplay /dev/vdb
```

### Volume Group (run inside the VM)

```bash
# Create a volume group named data_vg
sudo vgcreate data_vg /dev/vdb

# Verify the volume group
sudo vgdisplay data_vg
```

### Logical Volume (run inside the VM)

```bash
# Create a 4GB logical volume named app_lv
sudo lvcreate -n app_lv -L 4G data_vg

# Verify the logical volume
sudo lvdisplay /dev/data_vg/app_lv
```

## Requirements

- KVM/Libvirt must be installed and running on the host machine.
- `qemu-img` and `virsh` commands must be available and executable by the Ansible user.
- The `rhcsa-node1` virtual machine must exist.

## Role Variables

None currently defined.

## Dependencies

None.

## Example Playbook

```yaml
- name: Configure Virtualization Host
  hosts: localhost
  roles:
    - { role: lvm_rhcsa, tags: ["lvm", "setup"] }
```

## Usage

You can trigger this role via the project's Makefile:

```bash
make lvm_setup
```

## License

MIT
