#!/bin/bash

ACTION="$1"
LABEL="$2"

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

case "$ACTION" in
    mount)
	echo "Mounting $DEVICE..."
	udisksctl mount -b "$DEVICE"
	;;
    unmount|umount)
	echo "Unmounting $DEVICE..."
	udisksctl unmount -b "$DEVICE"
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
