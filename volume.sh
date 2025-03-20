#!/bin/bash
set -e

# Define the disk and mount point
DISK="/dev/sdb"
MOUNT_POINT="/data"

# Check if the disk exists
if [ ! -b "$DISK" ]; then
    echo "Disk $DISK not found. Exiting."
    exit 1
fi

# Check if the disk is already formatted
if ! blkid $DISK; then
    echo "Formatting the disk $DISK with ext4 filesystem..."
    sudo mkfs.ext4 -F $DISK
else
    echo "Disk $DISK is already formatted."
fi

# Create the mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating mount point at $MOUNT_POINT..."
    sudo mkdir -p $MOUNT_POINT
fi

# Mount the disk
echo "Mounting $DISK to $MOUNT_POINT..."
sudo mount $DISK $MOUNT_POINT

# Add to /etc/fstab for persistence
if ! grep -q "$DISK" /etc/fstab; then
    echo "$DISK $MOUNT_POINT ext4 defaults 0 2" | sudo tee -a /etc/fstab
fi

echo "Disk $DISK successfully mounted to $MOUNT_POINT."
