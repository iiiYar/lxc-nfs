# lxc-nfs

### 🚀 Proxmox VM & Container Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![Proxmox](https://img.shields.io/badge/Proxmox-VE-orange.svg)](https://www.proxmox.com/)

> **Automated Proxmox VM and LXC Container Management with Discord Notifications**

A powerful Bash script suite that automates the management of Proxmox Virtual Machines (VMs) and LXC containers, featuring automatic NFS mounting and real-time Discord notifications for comprehensive system monitoring.

## ✨ **What This Project Does For You**

This project solves common DevOps challenges by providing:

- **🔄 Automated VM Management**: Automatically starts, monitors, and manages Proxmox VMs
- **📦 LXC Container Orchestration**: Handles LXC container lifecycle with smart restart logic
- **📁 NFS Auto-Mounting**: Seamlessly mounts network storage directories
- **🔔 Real-time Monitoring**: Instant Discord notifications for all operations
- **🛡️ Error Handling**: Robust error handling with detailed logging
- **⚡ Zero-Downtime**: Intelligent container management to minimize service interruptions

## 🎯 **Use Cases**

- **Home Lab Automation**: Perfect for home server enthusiasts
- **Development Environments**: Automated setup of development VMs and containers
- **Media Server Management**: Ideal for Plex, Emby, or other media servers
- **Testing Environments**: Quick deployment and management of test VMs
- **Production Monitoring**: Real-time status updates for critical services

## 🚀 **Quick Start**

### Prerequisites
- Linux system (Ubuntu/Debian/CentOS/RHEL)
- Proxmox VE installed and configured
- Discord account with webhook access
- Network access to NFS storage

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/iiiYar/lxc-nfs.git
   cd proxmox-manager
   ```

2. **Run the installer**
   ```bash
   sudo chmod +x install.sh
   sudo ./install.sh
   ```

3. **Configure your settings**
   ```bash
   sudo nano /etc/proxmox-manager/config.conf
   ```

4. **Run the manager**
   ```bash
   sudo proxmox-manager
   ```

## ⚙️ **Configuration**

The installer will guide you through setting up:

- **Discord Webhook URL** for notifications
- **Proxmox connection details** (host, user, password)
- **VM and LXC container IDs** to manage
- **NFS server and mount paths**
- **Timing parameters** for operations

### Example Configuration
```bash
# Discord Configuration
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"

# Proxmox Configuration
PROXMOX_HOST="192.168.1.100"
PROXMOX_USER="root"
PROXMOX_PASSWORD="your_secure_password"

# VM Configuration
VM_ID="100"
VM_WAIT_TIME="20"

# LXC Configuration
LXC_ID="109"
LXC_WAIT_TIME="10"

# NFS Configuration
NFS_SERVER="192.168.1.200"
NFS_PATHS=(
    "/mnt/storage/media:/mnt/media"
    "/mnt/storage/documents:/mnt/docs"
)
```

## 📋 **How It Works**

### 1. **VM Management Process**
   - Checks current VM status
   - Starts VM if not running
   - Waits for full boot completion
   - Sends status notifications

### 2. **NFS Mounting**
   - Automatically mounts configured NFS shares
   - Handles mount failures gracefully
   - Provides real-time mount status

### 3. **LXC Container Management**
   - Monitors container health
   - Restarts containers intelligently
   - Ensures service continuity

### 4. **Discord Integration**
   - Real-time operation updates
   - Color-coded status messages
   - Emoji indicators for quick recognition

## 🔧 **Advanced Usage**

### Manual Execution
```bash
# Run the main manager
sudo /usr/local/bin/proxmox-manager

# Check configuration
sudo cat /etc/proxmox-manager/config.conf

# View logs
sudo journalctl -u proxmox-manager
```

### Cron Automation
```bash
# Add to crontab for automatic execution
sudo crontab -e

# Run every 5 minutes
*/5 * * * * /usr/local/bin/proxmox-manager

# Run at system startup
@reboot /usr/local/bin/proxmox-manager
```

## 🛡️ **Security Features**

- **Secure Configuration**: Config files with restricted permissions (600)
- **SSH Key Support**: Optional SSH key authentication setup
- **Password Protection**: Secure credential handling
- **Network Isolation**: Local network operation only

## 📊 **Monitoring & Notifications**

The script provides comprehensive Discord notifications:

- 🚀 **Script Start**: Blue notification when execution begins
- 🔍 **Status Checks**: Real-time VM and container status
- ✅ **Success Operations**: Green confirmations for completed tasks
- ⚠️ **Warnings**: Yellow alerts for informational messages
- ❌ **Errors**: Red notifications for failed operations
- 🎉 **Completion**: Purple confirmation when all tasks finish

## 🔍 **Troubleshooting**

### Common Issues

1. **SSH Connection Failed**
   ```bash
   # Test SSH connection
   sshpass -p "password" ssh user@host "echo 'test'"
   ```

2. **NFS Mount Failed**
   ```bash
   # Check NFS server accessibility
   showmount -e nfs-server-ip
   ```

3. **Permission Denied**
   ```bash
   # Fix script permissions
   sudo chmod 755 /usr/local/bin/proxmox-manager
   ```

### Debug Mode
```bash
# Enable debug output
sudo bash -x /usr/local/bin/proxmox-manager
```

## 📈 **Performance & Optimization**

- **Smart Waiting**: Configurable wait times for different operations
- **Parallel Operations**: Efficient resource utilization
- **Error Recovery**: Automatic retry mechanisms
- **Resource Monitoring**: Minimal system impact


## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- **Proxmox VE** for the excellent virtualization platform
- **Discord** for the webhook API
- **Linux community** for the robust shell scripting environment


---

**⭐ Star this repository if it helped you!**

