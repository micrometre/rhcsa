.PHONY: help configure_virtualization configure_vm_manager create_vms create_rhcsa_node1 create_repo_srv basic_setup nfs_setup dnf_repo_setup create_users vm_status workspace clean clean_all snap_create snap_list snap_list_all snap_delete snap_restore snap_current

# All VMs managed by this project
ALL_VMS := rhcsa-node1 repo-srv

help:
	@echo "Ansible Infrastructure Management"
	@echo ""
	@echo "Available targets:"
	@echo "  configure_virtualization - Configure virtualization support"
	@echo "  configure_vm_manager   - Configure VM manager"
	@echo "  create_vms             - Create all VMs (rhcsa-node1, repo-srv)"
	@echo "  create_rhcsa_node1     - Create RHCSA node1 VM"
	@echo "  create_repo_srv        - Create repo-srv VM"
	@echo "  basic_setup            - Update VMs and install basic utility packages"
	@echo "  nfs_setup              - Configure NFS server on repo-srv"
	@echo "  dnf_repo_setup         - Configure DNF repository on repo-srv"
	@echo "  create_users           - Create users inside node1"
	@echo "  vm_status              - Check status of VMs"
	@echo "  workspace              - Show VM workspace overview"
	@echo "  snap_create            - Create VM snapshot (VM_NAME required, SNAP optional)"
	@echo "  snap_list              - List VM snapshots (VM_NAME required)"
	@echo "  snap_list_all          - List snapshots for all VMs"
	@echo "  snap_delete            - Delete VM snapshot (VM_NAME and SNAP required)"
	@echo "  snap_restore           - Restore VM snapshot (VM_NAME and SNAP required)"
	@echo "  snap_current           - Show current VM snapshot (VM_NAME required)"
	@echo "  clean                  - Cleanup a specific VM (default: node1)"
	@echo "  clean_all              - Remove all VM images and workspace"

configure_virtualization:
	@echo "Configuring virtualization on ${HOST_NAME}..."
	ansible-playbook playbooks/configure.yml --tags virtualization
	@echo ""
	@echo "✅ ${HOST_NAME} configured with virtualization!"

configure_vm_manager:
	@echo "Configuring VM manager on ${HOST_NAME}..."
	ansible-playbook playbooks/configure.yml --tags vm-manager
	@echo ""
	@echo "✅ ${HOST_NAME} configured with VM manager!"

create_vms:
	@echo "Creating all VMs..."
	ansible-playbook playbooks/create_vms.yml
	@echo ""
	@echo "✅ All VMs created successfully!"

create_rhcsa_node1:
	@echo "Creating RHCSA node1 VM..."
	ansible-playbook playbooks/create_vms.yml -e "vm_name=rhcsa-node1"

create_repo_srv:
	@echo "Creating repo-srv VM..."
	ansible-playbook playbooks/create_vms.yml -e "vm_name=repo-srv"

basic_setup:
	@echo "Updating VMs and installing basic packages..."
	ansible-playbook playbooks/configure.yml --tags common
	@echo ""
	@echo "✅ VMs basic setup completed!"

nfs_setup:
	@echo "Configuring NFS Server on repo-srv..."
	ansible-playbook playbooks/configure.yml --tags nfs
	@echo ""
	@echo "✅ NFS Server configured successfully!"

dnf_repo_setup:
	@echo "Configuring DNF Repository on repo-srv..."
	ansible-playbook playbooks/configure.yml --tags dnf-repo
	@echo ""
	@echo "✅ DNF Repository configured successfully!"

create_users:
	@echo "Creating users..."
	ansible-playbook  playbooks/configure.yml --tags users -vv
	@echo ""
	@echo "✅ Users created successfully!"

lvm_setup:
	@echo "Configuring LVM and adding disk for rhcsa-node1..."
	ansible-playbook playbooks/configure.yml --tags lvm
	@echo ""
	@echo "✅ LVM setup completed!"


vm_status:
	@echo "Checking VM status..."
	ansible-playbook playbooks/configure.yml --tags vm-manager -e "vm_action=status" $(if $(VM_NAME),-e "vm_name=$(VM_NAME)",)

workspace:
	@echo "VM Workspace Overview..."
	ansible-playbook playbooks/configure.yml --tags vm-manager -e "vm_action=overview"

clean:
	@echo "Cleaning up VM..."
	ansible-playbook playbooks/configure.yml --tags vm-manager -e "vm_cleanup=true" $(if $(VM_NAME),-e "vm_name=$(VM_NAME)",)

clean_all:
	@echo "Cleaning all VMs and images..."
	@# Remove the workspace and images directories as defined in role defaults
	rm -rf $(HOME)/vm-workspace
	rm -rf $(HOME)/vm-images
	@echo "✅ All VM data cleaned!"

# ── Snapshot helpers ──────────────────────────────────────────────────
define check_vm
	@if [ -z "$(VM_NAME)" ]; then \
		echo "❌ Error: VM_NAME is required."; \
		echo "Usage: make $@ VM_NAME=<vm-name>"; \
		exit 1; \
	fi
endef

define check_snap
	@if [ -z "$(SNAP)" ]; then \
		echo "❌ Error: SNAP is required."; \
		echo "Usage: make $@ VM_NAME=<vm-name> SNAP=<snapshot-name>"; \
		exit 1; \
	fi
endef

snap_create:
	$(check_vm)
	@echo "Creating snapshot for VM $(VM_NAME)..."
	ansible-playbook playbooks/configure.yml --tags snapshot \
		-e "snapshot_action=create" \
		-e "vm_name=$(VM_NAME)" \
		$(if $(SNAP),-e "snapshot_name=$(SNAP)",)
	@echo "✅ Snapshot created!"

snap_list:
	$(check_vm)
	@echo "Listing snapshots for VM $(VM_NAME)..."
	ansible-playbook playbooks/configure.yml --tags snapshot \
		-e "snapshot_action=list" \
		-e "vm_name=$(VM_NAME)"

snap_list_all:
	@$(foreach vm,$(ALL_VMS), \
		echo "=== $(vm) ===" ; \
		virsh snapshot-list $(vm) --tree 2>/dev/null || echo "  No snapshots or VM not found" ; \
		echo "" ; \
	)

snap_delete:
	$(check_vm)
	$(check_snap)
	@echo "Deleting snapshot '$(SNAP)' from VM $(VM_NAME)..."
	ansible-playbook playbooks/configure.yml --tags snapshot \
		-e "snapshot_action=delete" \
		-e "vm_name=$(VM_NAME)" \
		-e "snapshot_name=$(SNAP)"
	@echo "✅ Snapshot '$(SNAP)' deleted!"

snap_restore:
	$(check_vm)
	$(check_snap)
	@echo "Restoring snapshot '$(SNAP)' for VM $(VM_NAME)..."
	ansible-playbook playbooks/configure.yml --tags snapshot \
		-e "snapshot_action=restore" \
		-e "vm_name=$(VM_NAME)" \
		-e "snapshot_name=$(SNAP)"
	@echo "✅ Snapshot '$(SNAP)' restored!"

snap_current:
	$(check_vm)
	@echo "Showing current snapshot for VM $(VM_NAME)..."
	ansible-playbook playbooks/configure.yml --tags snapshot \
		-e "snapshot_action=current" \
		-e "vm_name=$(VM_NAME)"

# Legacy compatibility targets
check: vm_status
status: vm_status
snapshot_create: snap_create
snapshot_list: snap_list
snapshot_delete: snap_delete
snapshot_restore: snap_restore
snapshot_current: snap_current
list_all_snapshots: snap_list_all

