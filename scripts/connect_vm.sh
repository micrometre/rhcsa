#!/bin/bash

# Configuration
VM_USER="ubuntu"
VM_IP="10.225.170.140"
VM_NAME="cbwanpr"

echo "Checking if xrdp is running on $VM_NAME..."

# 1. Check if xrdp is installed and running on the VM
ssh -t $VM_USER@$VM_IP "sudo systemctl is-active --quiet xrdp && echo 'xrdp is running!' || (echo 'Installing/Starting xrdp...' && sudo apt update && sudo apt install -y xrdp && sudo systemctl enable --now xrdp)"

# 2. Launch the Remmina Remote Desktop client on your host
# Remmina is pre-installed on most Ubuntu desktops.
echo "Launching Remote Desktop connection..."
remmina -c rdp://$VM_USER@$VM_IP &

echo "Connection process initiated."