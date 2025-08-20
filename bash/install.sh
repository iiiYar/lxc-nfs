#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Proxmox VM & Container Manager Installation ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Install required packages
echo -e "\n${BLUE}Installing required packages...${NC}"
if command -v apt-get >/dev/null; then
    apt-get update
    apt-get install -y sshpass curl nfs-common
elif command -v yum >/dev/null; then
    yum update
    yum install -y sshpass curl nfs-utils
else
    echo -e "${RED}Unsupported package manager${NC}"
    exit 1
fi

# Create necessary directories
echo -e "\n${BLUE}Creating directories...${NC}"
mkdir -p /mnt/moves /mnt/tv /etc/proxmox-manager

# Interactive configuration
echo -e "\n${BLUE}Starting interactive configuration...${NC}"

# Discord Configuration
echo -e "\n${GREEN}Discord Configuration:${NC}"
read -p "Enter Discord webhook URL: " DISCORD_WEBHOOK

# Proxmox Configuration
echo -e "\n${GREEN}Proxmox Configuration:${NC}"
read -p "Enter Proxmox host IP: " PROXMOX_HOST
read -p "Enter Proxmox username [root]: " PROXMOX_USER
PROXMOX_USER=${PROXMOX_USER:-root}
read -s -p "Enter Proxmox password: " PROXMOX_PASS
echo

# VM Configuration
echo -e "\n${GREEN}VM Configuration:${NC}"
read -p "Enter VM ID [100]: " VM_ID
VM_ID=${VM_ID:-100}
read -p "Enter VM startup wait time in seconds [20]: " VM_WAIT
VM_WAIT=${VM_WAIT:-20}

# LXC Configuration
echo -e "\n${GREEN}LXC Configuration:${NC}"
read -p "Enter LXC container ID [109]: " LXC_ID
LXC_ID=${LXC_ID:-109}
read -p "Enter LXC operation wait time in seconds [10]: " LXC_WAIT
LXC_WAIT=${LXC_WAIT:-10}

# NFS Configuration
echo -e "\n${GREEN}NFS Configuration:${NC}"
read -p "Enter NFS server IP: " NFS_SERVER

echo "Enter NFS paths (press Enter twice to finish)"
echo "Format: /source/path:/mount/point"
NFS_PATHS=()
while true; do
    read -p "NFS path (or press Enter to finish): " path
    if [ -z "$path" ]; then
        break
    fi
    NFS_PATHS+=("$path")
done

# Create configuration file
echo -e "\n${BLUE}Creating configuration file...${NC}"
cat > /etc/proxmox-manager/config.conf << EOF
# Discord Configuration
DISCORD_WEBHOOK_URL="$DISCORD_WEBHOOK"

# Proxmox Configuration
PROXMOX_HOST="$PROXMOX_HOST"
PROXMOX_USER="$PROXMOX_USER"
PROXMOX_PASSWORD="$PROXMOX_PASS"

# VM Configuration
VM_ID="$VM_ID"
VM_WAIT_TIME="$VM_WAIT"

# LXC Configuration
LXC_ID="$LXC_ID"
LXC_WAIT_TIME="$LXC_WAIT"

# NFS Configuration
NFS_SERVER="$NFS_SERVER"
NFS_PATHS=(
$(for path in "${NFS_PATHS[@]}"; do echo "    \"$path\""; done)
)
EOF

# Set secure permissions
chmod 600 /etc/proxmox-manager/config.conf

# Copy and set permissions for main script
echo -e "\n${BLUE}Installing scripts...${NC}"
install -m 755 vm_container_manager.sh /usr/local/bin/
ln -sf /usr/local/bin/vm_container_manager.sh /usr/local/bin/proxmox-manager

# Test SSH connection
echo -e "\n${BLUE}Testing SSH connection to Proxmox...${NC}"
if sshpass -p "$PROXMOX_PASS" ssh -o StrictHostKeyChecking=no "$PROXMOX_USER@$PROXMOX_HOST" "echo 'Connection successful'"; then
    echo -e "${GREEN}SSH connection test successful${NC}"
else
    echo -e "${RED}SSH connection test failed${NC}"
    echo "Please verify your Proxmox credentials and try again"
fi

# Setup SSH key (optional)
echo -e "\n${BLUE}SSH Key Setup${NC}"
read -p "Do you want to setup SSH key authentication? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/proxmox_rsa -N ""
    sshpass -p "$PROXMOX_PASS" ssh-copy-id -i ~/.ssh/proxmox_rsa.pub "$PROXMOX_USER@$PROXMOX_HOST"
fi

# Test NFS mounts
echo -e "\n${BLUE}Testing NFS mounts...${NC}"
for path in "${NFS_PATHS[@]}"; do
    source_path=$(echo "$path" | cut -d':' -f1)
    mount_point=$(echo "$path" | cut -d':' -f2)
    
    if mount -t nfs4 "$NFS_SERVER:$source_path" "$mount_point"; then
        echo -e "${GREEN}Successfully mounted $mount_point${NC}"
        umount "$mount_point"
    else
        echo -e "${RED}Failed to mount $mount_point${NC}"
    fi
done

echo -e "\n${GREEN}Installation completed successfully!${NC}"
echo -e "You can now run the script using: ${BLUE}proxmox-manager${NC}"
echo -e "Configuration file is located at: ${BLUE}/etc/proxmox-manager/config.conf${NC}"
echo -e "If you need to modify settings later, edit the configuration file"
