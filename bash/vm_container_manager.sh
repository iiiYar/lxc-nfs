#!/usr/bin/env bash

# Enable debugging
set -x

# Source configuration file
if [ -f /etc/proxmox-manager/config.conf ]; then
    source /etc/proxmox-manager/config.conf
else
    echo "Error: Configuration file not found"
    exit 1
fi

# Validate configuration
if [ -z "$DISCORD_WEBHOOK_URL" ] || [ -z "$PROXMOX_HOST" ] || [ -z "$PROXMOX_PASSWORD" ]; then
    echo "Error: Missing required configuration"
    exit 1
fi

# Send a message to Discord using embeds and markdown
send_discord_notification() {
    local title="$1"
    local description="$2"
    local color="$3"
    local emoji="$4" # Optional, can be empty
    curl -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"embeds\": [{
                \"title\": \"$emoji $title\",
                \"description\": \"$description\",
                \"color\": $color
            }]
        }"
}

# Notify start of the script
send_discord_notification \
    "Script Execution Started" \
    "The script has started executing.\n\n_Status: In progress..._" \
    3447003  # Blue color \
    "🚀"

# Check the current status of VM 100 on Proxmox-1
VM_STATUS=$(sshpass -p "$PROXMOX_PASSWORD" ssh "$PROXMOX_USER@$PROXMOX_HOST" "qm status $VM_ID | awk '{print \$2}'")

# Check if the VM status check command was successful
if [ $? -eq 0 ]; then
    send_discord_notification \
        "Checking VM Status" \
        "VM $VM_ID Status\n\n- Host: $PROXMOX_HOST\n- Current Status: \`$VM_STATUS\`" \
        7506394  # Blue color \
        "🔍"
else
    send_discord_notification \
        "Error Checking VM Status" \
        "Failed to check the status of VM $VM_ID on $PROXMOX_HOST.\n\n_Please check the system._" \
        16711680  # Red color \
        "❌"
    exit 1
fi

# If the VM is not running, start it
if [ "$VM_STATUS" != "running" ]; then
    sshpass -p "$PROXMOX_PASSWORD" ssh "$PROXMOX_USER@$PROXMOX_HOST" "qm start $VM_ID"
    if [ $? -eq 0 ]; then
        send_discord_notification \
            "VM Started" \
            "VM $VM_ID on $PROXMOX_HOST has been started successfully." \
            65280  # Green color \
            "✅"
    else
        send_discord_notification \
            "Error Starting VM" \
            "Failed to start VM $VM_ID on $PROXMOX_HOST.\n\n_Please check the system._" \
            16711680  # Red color \
            "❌"
        exit 1
    fi
else
    send_discord_notification \
        "VM Already Running" \
        "VM $VM_ID is already running.\n_No action needed._" \
        16776960  # Yellow color \
        "ℹ️"
fi

# Wait until VM status is 'running'
until [ "$VM_STATUS" == "running" ]; do
    sleep 5
    VM_STATUS=$(sshpass -p "$PROXMOX_PASSWORD" ssh "$PROXMOX_USER@$PROXMOX_HOST" "qm status $VM_ID | awk '{print \$2}'")
done

# Wait for additional time to ensure VM is fully up
sleep 20

# Send notification about mounting shared directories
send_discord_notification \
    "Mounting Directories" \
    "Mounting shared directories via NFS..." \
    7506394  # Blue color \
    "📁"

# Mount shared directories via NFS
IFS=':' read -ra NFS_PATHS_ARRAY <<< "${NFS_PATHS[@]}"
for path in "${NFS_PATHS_ARRAY[@]}"; do
    source_path=$(echo "$path" | cut -d':' -f1)
    mount_point=$(echo "$path" | cut -d':' -f2)
    
    mount -t nfs4 "$NFS_SERVER:$source_path" "$mount_point"
    if [ $? -ne 0 ]; then
        send_discord_notification \
            "Error Mounting Directory" \
            "Failed to mount $source_path to $mount_point.\n\n_Please check the system._" \
            16711680 \
            "❌"
        exit 1
    fi
done

# Wait for additional time after mounting
sleep 10

# Check the current status of LXC container
LXC_STATUS=$(lxc-info -n "$LXC_ID" | grep State | awk '{print $2}')

# Check if the LXC status check command was successful
if [ $? -eq 0 ]; then
    send_discord_notification \
        "Checking LXC Container Status" \
        "LXC Container $LXC_ID Status\n\n- Current Status: \`$LXC_STATUS\`" \
        7506394  # Blue color \
        "🔍"
else
    send_discord_notification \
        "Error Checking LXC Status" \
        "Failed to check the status of LXC container $LXC_ID.\n\n_Please check the system._" \
        16711680  # Red color \
        "❌"
    exit 1
fi

# If the container is running, restart it; otherwise, start it
if [ "$LXC_STATUS" == "RUNNING" ]; then
    lxc-stop -n "$LXC_ID"
    sleep 5  # Wait for a few seconds to ensure the container is fully stopped
    lxc-start -n "$LXC_ID"
    if [ $? -eq 0 ]; then
        send_discord_notification \
            "LXC Container Restarted" \
            "LXC Container $LXC_ID has been restarted successfully." \
            65280  # Green color \
            "🔄"
    else
        send_discord_notification \
            "Error Restarting LXC Container" \
            "Failed to restart LXC container $LXC_ID.\n\n_Please check the system._" \
            16711680  # Red color \
            "❌"
        exit 1
    fi
else
    lxc-start -n "$LXC_ID"
    if [ $? -eq 0 ]; then
        send_discord_notification \
            "LXC Container Started" \
            "LXC Container $LXC_ID has been started." \
            65280  # Green color \
            "✅"
    else
        send_discord_notification \
            "Error Starting LXC Container" \
            "Failed to start LXC container $LXC_ID.\n\n_Please check the system._" \
            16711680  # Red color \
            "❌"
        exit 1
    fi
fi

# Notify end of the script
send_discord_notification \
    "Script Execution Completed" \
    "The script has completed successfully.\n\n_All tasks are done._" \
    3066993  # Purple color \
    "🎉"

# Disable debugging
set +x
