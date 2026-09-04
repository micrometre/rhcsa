# NFS and DNF Repository Setup for RHCSA Practice

This guide demonstrates setting up an NFS server and local DNF repository - two critical skills for the RHCSA exam. These services are commonly tested and represent real-world system administration scenarios.

## RHCSA Exam Relevance

**NFS (Network File System):**
- **Exam Objective:** Configure network storage (NFS)
- **Key Skills Tested:** Exporting directories, managing `/etc/exports`, firewall configuration, client mounting
- **Common Exam Tasks:** Create NFS exports, configure client access, troubleshoot mount issues

**DNF/YUM Repository:**
- **Exam Objective:** Configure local repositories
- **Key Skills Tested:** Setting up web servers (httpd), creating repository metadata with `createrepo`, configuring client repo files
- **Common Exam Tasks:** Create custom repositories, configure systems to use local repos, troubleshoot package installation

## Learning Objectives

By completing this lab, you will practice:
1. **Service Management:** Enabling and starting systemd services (`nfs-server`, `httpd`)
2. **Firewall Configuration:** Using `firewall-cmd` to open required ports
3. **SELinux Contexts:** Understanding and fixing file context issues with `restorecon`
4. **Network Services:** Configuring NFS exports and Apache web server
5. **Package Management:** Creating and using local DNF repositories
6. **Troubleshooting:** Diagnosing service failures and connectivity issues

## Architecture Overview

```
┌─────────────────┐         ┌─────────────────┐
│   repo-srv      │         │   rhcsa-node1   │
│  (192.168.122.x)│         │  (192.168.122.y)│
├─────────────────┤         ├─────────────────┤
│  NFS Server     │◄────────│  NFS Client     │
│  /shares/public │         │  /mnt/nfs       │
├─────────────────┤         ├─────────────────┤
│  HTTP Server    │◄────────│  DNF Client     │
│  /var/www/html  │         │  /etc/yum.repos.d│
└─────────────────┘         └─────────────────┘
```

## Best Practices & Security Considerations

### NFS Security
- **`no_root_squash`**: Used in this lab for convenience, but **not recommended in production**. It allows root users on clients to have root access on the server. In production, use `root_squash` (default) or specific UID/GID mappings.
- **Network Segmentation**: Limit exports to specific subnets or hostnames rather than using broad ranges like `0.0.0.0/0`.
- **Read-Only Exports**: Use `ro` instead of `rw` when clients only need to read data.

### DNF Repository Security
- **GPG Checking**: Set `gpgcheck=1` in production and properly sign your packages. This lab uses `gpgcheck=0` for simplicity.
- **SELinux**: Always ensure proper SELinux contexts for web content. The `restorecon` command is essential for Apache to serve files correctly.
- **Firewall**: Only expose HTTP/HTTPS ports to trusted networks.

## Common Pitfalls & Troubleshooting

### NFS Issues
1. **Mount fails with "Permission denied"**: Check `/etc/exports` syntax and ensure the client IP is in the allowed range. Run `exportfs -rv` to reload exports.
2. **"Stale file handle" errors**: Usually occurs when the server export was changed while mounted. Unmount and remount on the client.
3. **Firewall blocking**: Ensure `nfs`, `mountd`, and `rpc-bind` services are allowed through firewalld.

### DNF Repository Issues
1. **"Repomd.xml not found"**: The repository metadata wasn't generated or is in the wrong location. Run `createrepo` in the correct directory.
2. **SELinux denials**: Apache cannot read files due to incorrect context. Use `restorecon -Rv /var/www/html` to fix.
3. **Package not found**: Verify the `.repo` file `baseurl` matches the actual directory structure on the server.

## Performance Considerations

- **NFS**: Use `sync` for data integrity (default) or `async` for better performance at the cost of potential data loss on crashes.
- **DNF Repos**: For large repositories, consider using `--update` flag with `createrepo` to only update changed packages rather than regenerating all metadata.

---

## Manual Setup Instructions

> **NOTE:** This guide has been fully automated via Ansible.
> To deploy the NFS Server on `repo-srv`, run: `make nfs_setup`
> The instructions below are kept for manual reference and learning purposes.
> ---

### NFS Server Setup

# 1. Install nfs-utils
sudo dnf install -y nfs-utils

# 2. Create the shared export folder
sudo mkdir -p /shares/public
sudo chmod 777 /shares/public
echo "Welcome to the RHCSA NFS lab" | sudo tee /shares/public/testfile.txt

# 3. Define the export (/etc/exports)
# Replace subnet with your libvirt network CIDR
echo '/shares/public 192.168.122.0/24(rw,sync,no_root_squash)' | sudo tee /etc/exports

# 4. Reload exports after modifying /etc/exports
sudo exportfs -rv

# 5. Enable and start NFS server
sudo systemctl enable --now nfs-server

# 6. Open Firewall ports
sudo firewall-cmd --permanent --add-service=nfs
sudo firewall-cmd --permanent --add-service=mountd
sudo firewall-cmd --permanent --add-service=rpc-bind
sudo firewall-cmd --reload



### DNF Repository Setup

> **NOTE:** This guide has been fully automated via Ansible.
> To deploy the DNF repository on `repo-srv`, run: `make dnf_repo_setup`
> The instructions below are kept for manual reference and learning purposes.
> ---

# 1. Install Apache and createrepo tooling
sudo dnf install -y httpd createrepo

# 2. Create the document root directory for repos
sudo mkdir -p /var/www/html/repos/custom

# 3. Add sample test packages or mount the full AlmaLinux ISO
# If you have the ISO on the host, pass it in and mount it:
# mount -o loop /dev/cdrom /var/www/html/repos/
# Alternatively, download a couple of test RPMs into custom/:
sudo dnf download --destdir=/var/www/html/repos/custom zsh tmux

# 4. Generate repository metadata
# This creates the repomd.xml and other metadata files required by DNF
sudo createrepo /var/www/html/repos/custom

# 5. Fix SELinux context for the web root
# Apache requires httpd_sys_content_t context to serve files
sudo restorecon -Rv /var/www/html

# 6. Start Apache and open firewalld
sudo systemctl enable --now httpd
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload


## Verification from Client (rhcsa-node1)

Switch to your main RHCSA practice VM (rhcsa-node1) and test both services. This verification process is itself a key exam skill - you must be able to confirm services are working correctly.

### Test NFS Export

```bash
# Discover available shares from the server
showmount -e <repo-srv-ip>

# Test manual mount (RHCSA exam skill)
sudo mkdir -p /mnt/nfs
sudo mount -t nfs <repo-srv-ip>:/shares/public /mnt/nfs

# Verify the mount
df -h | grep nfs
cat /mnt/nfs/testfile.txt

# Clean up
sudo umount /mnt/nfs
```

**Exam Tip:** In the exam, you may be asked to make NFS mounts persistent. Add the following to `/etc/fstab`:
```
<repo-srv-ip>:/shares/public /mnt/nfs nfs defaults 0 0
```

### Test Local DNF Repo

```bash
# Create a .repo file on the client
sudo tee /etc/yum.repos.d/local-lab.repo <<EOF
[local-lab]
name=RHCSA Lab Local Repo
baseurl=http://<repo-srv-ip>/repos/custom
enabled=1
gpgcheck=0
EOF

# Clear DNF cache and test the repository
sudo dnf clean all
sudo dnf --disablerepo="*" --enablerepo="local-lab" list available

# Install a package from the local repo to verify
sudo dnf --disablerepo="*" --enablerepo="local-lab" install -y zsh
```

**Exam Tip:** When troubleshooting DNF issues, check:
1. Repository file syntax (brackets, baseurl format)
2. Network connectivity to the repo server
3. SELinux contexts on the server
4. Firewall rules on the server
5. Repository metadata (repomd.xml exists and is accessible)

## RHCSA Exam Strategy

### Time Management
- **NFS Tasks:** Usually 5-10 minutes if you're comfortable with the commands
- **DNF Repo Tasks:** Usually 5-8 minutes, plus time for package downloads if needed
- **Combined:** Budget 15-20 minutes for both tasks together

### Common Exam Scenarios

1. **"Configure NFS export"**: You'll need to:
   - Install `nfs-utils`
   - Create the directory to export
   - Edit `/etc/exports` with correct syntax
   - Enable and start `nfs-server`
   - Configure firewall
   - Reload exports with `exportfs -rv`

2. **"Configure system to use NFS"**: You'll need to:
   - Install `nfs-utils` on client
   - Create mount point
   - Mount manually first (to verify)
   - Add to `/etc/fstab` for persistence (if required)

3. **"Create a local repository"**: You'll need to:
   - Install `httpd` and `createrepo`
   - Create directory structure
   - Add packages (may need to download or copy from provided location)
   - Run `createrepo`
   - Fix SELinux contexts
   - Start `httpd` and configure firewall
   - Create `.repo` file on client

4. **"Configure system to use local repository"**: You'll need to:
   - Create `.repo` file in `/etc/yum.repos.d/`
   - Test with `dnf list` or install a package
   - May need to disable other repos temporarily

### Verification Commands (Memorize These)

```bash
# NFS verification
showmount -e <server-ip>          # Show available exports
exportfs -v                        # Show current exports on server
mount | grep nfs                   # Show mounted NFS shares
systemctl status nfs-server        # Check NFS service status

# DNF verification
dnf repolist                       # List enabled repositories
dnf repolist --all                 # List all repositories (enabled/disabled)
dnf info <package>                # Show package info
dnf provides <file>                # Find which package provides a file
cat /etc/yum.repos.d/*.repo       # Review all repo files
```

## Beyond the Exam: Real-World Applications

### Enterprise NFS Use Cases
- **Home Directories**: Centralized user home directories for consistency across servers
- **Application Data**: Shared application data between web servers
- **Backup Storage**: Centralized backup target
- **Media Storage**: Shared media files for streaming services

### Enterprise DNF Repo Use Cases
- **Air-Gapped Environments**: Systems without internet access need local repos
- **Custom Software**: Distributing internally developed packages
- **Version Control**: Pin specific package versions for consistency
- **Bandwidth Optimization**: Reduce external bandwidth usage
- **Compliance**: Control exactly which packages can be installed

## Additional Resources

### Man Pages to Study
- `man exports` - NFS export configuration
- `man exportfs` - Export management
- `man createrepo` - Repository metadata creation
- `man yum.conf` - DNF/YUM configuration options

### Related RHCSA Objectives
- Configure network storage (NFS)
- Configure local repositories
- Manage firewall rules using firewalld
- Manage SELinux contexts
- Configure systemd services