.PHONY: help configure_virtualization configure_vm_manager create_vms create_rhcsa_node1 create_repo_srv basic_setup nfs_setup dnf_repo_setup create_users vm_status workspace clean clean_all

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


# Legacy compatibility targets
check: vm_status
status: vm_status
