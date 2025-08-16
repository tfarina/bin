#!/bin/bash

ACTION="$1"
LABEL="$2"
MOUNT_BASE="/media/$USER"

if [[ -z "$ACTION" || -z "$LABEL" ]]; then
    echo "Usage: $0 {mount|unmount|status} <LABEL>"
    exit 1
fi

# Find device by label
DEVICE=$(lsblk -o NAME,LABEL --raw | grep "$LABEL" | awk '{print "/dev/" $1}')

if [[ -z "$DEVICE" ]]; then
    echo "Device with label '$LABEL' not found."
    exit 1
fi


MOUNTPOINT="$MOUNT_BASE/$LABEL"

case "$ACTION" in
    mount)
	echo "Mounting $DEVICE to $MOUNTPOINT..."
	sudo mkdir -p "$MOUNTPOINT"
	sudo mount "$DEVICE" "$MOUNTPOINT"
	;;
    unmount|umount)
	echo "Unmounting $DEVICE from $MOUNTPOINT..."
	sudo umount "$MOUNTPOINT"
	;;
    status)
	MOUNTPOINT=$(lsblk -o NAME,LABEL,MOUNTPOINT --raw | grep "$LABEL" | awk '{print $3}')
	if [[ -n "$MOUNTPOINT" ]]; then
	    echo "$LABEL is mounted at $MOUNTPOINT"
	else
	    echo "$LABEL is not mounted"
	fi
	;;
    *)
	echo "Invalid action: $ACTION"
	echo "Usage: $0 {mount|unmount|status} <LABEL>"
	exit 1
	;;
esac
