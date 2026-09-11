# ── LVM RHCSA targets ─────────────────────────────────────────────────
.PHONY: lvm_setup lvm_clean lvm_reconfigure lvm_install lvm_create_disk lvm_create_pv lvm_create_vg lvm_create_lv lvm_format_mount lvm_extend_lv lvm_summary lvm_add_hd lvm_prepare_vdc lvm_pvmove

lvm_setup:
	@echo "Configuring LVM and adding disk for rhcsa-node1..."
	ansible-playbook playbooks/configure.yml --tags lvm
	@echo ""
	@echo "✅ LVM setup completed!"

lvm_clean:
	@echo "Cleaning up LVM configuration on rhcsa-node1..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=clean"
	@echo ""
	@echo "✅ LVM cleanup completed!"

lvm_reconfigure:
	@echo "Reconfiguring LVM (clean + setup)..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=clean"
	ansible-playbook playbooks/configure.yml --tags lvm
	@echo ""
	@echo "✅ LVM reconfigured successfully!"

lvm_install:
	@echo "Installing lvm2 package inside the VM..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=install_lvm"
	@echo ""
	@echo "✅ lvm2 installed!"

lvm_create_disk:
	@echo "Creating and attaching 10GB disk (vdb)..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=create_disk"
	@echo ""
	@echo "✅ Disk created and attached!"

lvm_create_pv:
	@echo "Creating Physical Volume on /dev/vdb..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=create_pv"
	@echo ""
	@echo "✅ Physical Volume created!"

lvm_create_vg:
	@echo "Creating Volume Group data_vg..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=create_vg"
	@echo ""
	@echo "✅ Volume Group created!"

lvm_create_lv:
	@echo "Creating Logical Volumes (app_lv, db_lv)..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=create_lv"
	@echo ""
	@echo "✅ Logical Volumes created!"

lvm_format_mount:
	@echo "Formatting db_lv with XFS and mounting to /mnt/database..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=format_mount"
	@echo ""
	@echo "✅ db_lv formatted and mounted!"

lvm_extend_lv:
	@echo "Extending db_lv by 1G..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=extend_lv"
	@echo ""
	@echo "✅ db_lv extended!"

lvm_summary:
	@echo "Showing LVM summary..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=lvm_summary"
	@echo ""
	@echo "✅ Summary complete!"

lvm_add_hd:
	@echo "Adding new 10GB hard drive (vdc) to rhcsa-node1..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=add_hd"
	@echo ""
	@echo "✅ New hard drive added successfully!"

lvm_prepare_vdc:
	@echo "Initializing /dev/vdc as PV and adding to data_vg..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=prepare_vdc"
	@echo ""
	@echo "✅ /dev/vdc prepared and added to data_vg!"

lvm_pvmove:
	@echo "Migrating data from vdb to vdc using pvmove..."
	ansible-playbook playbooks/configure.yml --tags lvm -e "lvm_action=pvmove"
	@echo ""
	@echo "✅ Data migration completed successfully!"

