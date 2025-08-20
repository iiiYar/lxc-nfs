#!/usr/bin/env bash

# Enable debugging
set -x

# Define webhook URL
WEBHOOK_URL="https://discord.com/api/webhooks/1285100619199283210/rxY_yl26EImztFdXT9jC4uqfTeZoKixaAUHH2bzOQZdBeAfpCW5SVzxoggXUyp04NDZx"

# Send a message to Discord using embeds and markdown
send_discord_notification() {
    local title="$1"
    local description="$2"
    local color="$3"
    local emoji="$4" # Optional, can be empty
    curl -X POST "$WEBHOOK_URL" \
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
    "**The script has started executing.**\n\n_Status: In progress..._" \
    3447003  # Blue color
    "??"

# Check the current status of VM 100 on Proxmox-1
VM_STATUS=$(sshpass -p "14231423" ssh root@192.168.0.132 'qm status 100 | awk "{print \$2}"')

# Check if the VM status check command was successful
if [ $? -eq 0 ]; then
    send_discord_notification \
        "Checking VM Status" \
        "**VM 100 Status**\n\n- **Host**: Proxmox-1\n- **Current Status**: \`$VM_STATUS\`" \
        7506394  # Blue color
        "??"
else
    send_discord_notification \
        "Error Checking VM Status" \
        "**Failed to check the status of VM 100 on Proxmox-1.**\n\n_Please check the system._" \
        16711680  # Red color
        "?"
    exit 1
fi

# If the VM is not running, start it
if [ "$VM_STATUS" != "running" ]; then
    sshpass -p "14231423" ssh root@192.168.0.132 "qm start 100"
    if [ $? -eq 0 ]; then
        send_discord_notification \
            "VM Started" \
            "**VM 100 on Proxmox-1 has been started successfully.**" \
            65280  # Green color
            "?"
    else
        send_discord_notification \
            "Error Starting VM" \
            "**Failed to start VM 100 on Proxmox-1.**\n\n_Please check the system._" \
            16711680  # Red color
            "?"
        exit 1
    fi
else
    send_discord_notification \
        "VM Already Running" \
        "**VM 100 is already running.**\n_No action needed._" \
        16776960  # Yellow color
        "??"
fi

# Wait until VM 100 status is 'running'
until [ "$VM_STATUS" == "running" ]; do
    sleep 5
    VM_STATUS=$(sshpass -p "14231423" ssh root@192.168.0.132 'qm status 100 | awk "{print \$2}"')
done

# Wait for additional time to ensure VM 100 is fully up
sleep 20

# Send notification about mounting shared directories
send_discord_notification \
    "Mounting Directories" \
    "**Mounting shared directories via NFS...**" \
    7506394  # Blue color
    "??"

# Mount shared directories via NFS
mount -t nfs4 192.168.189:/mnt/tank/media/moves /mnt/moves
if [ $? -eq 0 ]; then
    mount -t nfs4 192.168.189:/mnt/tank/media/tv-series /mnt/tv
    if [ $? -eq 0 ]; then
        send_discord_notification \
            "Directories Mounted" \
            "**Shared directories have been mounted successfully.**\n\n_Mounting complete._" \
            65280  # Green color
            "?"
    else
        send_discord_notification \
            "Error Mounting Directories" \
            "**Failed to mount one of the shared directories.**\n\n_Please check the system._" \
            16711680  # Red color
            "?"
        exit 1
    fi
else
    send_discord_notification \
        "Error Mounting Directories" \
        "**Failed to mount the directories.**\n\n_Please check the system._" \
        16711680  # Red color
        "?"
    exit 1
fi

# Wait for additional time after mounting
sleep 10

# Check the current status of LXC container 109 on the current server (Proxmox-2)
LXC_STATUS=$(lxc-info -n 109 | grep "State:" | awk '{print $2}')

# Check if the LXC status check command was successful
if [ $? -eq 0 ]; then
    send_discord_notification \
        "Checking LXC Container Status" \
        "**LXC Container 109 Status**\n\n- **Current Status**: \`$LXC_STATUS\`" \
        7506394  # Blue color
        "??"
else
    send_discord_notification \
        "Error Checking LXC Status" \
        "**Failed to check the status of LXC container 109.**\n\n_Please check the system._" \
        16711680  # Red color
        "?"
    exit 1
fi

# If the container is running, restart it; otherwise, start it
if [ "$LXC_STATUS" == "RUNNING" ]; then
    lxc-stop -n 109
    sleep 5  # Wait for a few seconds to ensure the container is fully stopped
    lxc-start -n 109
    if [ $? -eq 0 ]; then
        send_discord_notification \
            "LXC Container Restarted" \
            "**LXC Container 109 has been restarted successfully.**" \
            65280  # Green color
            "?"
    else
        send_discord_notification \
            "Error Restarting LXC Container" \
            "**Failed to restart LXC container 109.**\n\n_Please check the system._" \
            16711680  # Red color
            "?"
        exit 1
    fi
else
    lxc-start -n 109
    if [ $? -eq 0 ]; then
        send_discord_notification \
            "LXC Container Started" \
            "**LXC Container 109 has been started.**" \
            65280  # Green color
            "?"
    else
        send_discord_notification \
            "Error Starting LXC Container" \
            "**Failed to start LXC container 109.**\n\n_Please check the system._" \
            16711680  # Red color
            "?"
        exit 1
    fi
fi

# Notify end of the script
send_discord_notification \
    "Script Execution Completed" \
    "**The script has completed successfully.**\n\n_All tasks are done._" \
    3066993  # Purple color
    "??"

# Disable debugging
set +x