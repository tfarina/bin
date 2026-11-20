#!/bin/bash

action="$1"
label="$2"

if [[ -z "$action" || -z "$label" ]]; then
    echo "Usage: $0 {mount|unmount|status} <LABEL>"
    exit 1
fi

# Find device by label
device=$(lsblk -o NAME,LABEL --raw | grep "$label" | awk '{print "/dev/" $1}')

if [[ -z "$device" ]]; then
    echo "Device with label '$label' not found."
    exit 1
fi

mountPoint="/media/$USER/$label"

case "$action" in
    mount)
	echo "Mounting $device to $mountPoint..."
	sudo mkdir -p "$mountPoint"
	sudo mount -o rw,uid=$(id -u),gid=$(id -g),fmask=0022,dmask=0022,utf8=1,shortname=mixed "$device" "$mountPoint"
	;;
    unmount|umount)
	echo "Unmounting $device from $mountPoint..."
	sudo umount "$mountPoint"
	;;
    status)
	mountPoint=$(lsblk -o NAME,LABEL,MOUNTPOINT --raw | grep "$label" | awk '{print $3}')
	if [[ -n "$mountPoint" ]]; then
	    echo "$label is mounted at $mountPoint"
	else
	    echo "$label is not mounted"
	fi
	;;
    *)
	echo "Invalid action: $action"
	echo "Usage: $0 {mount|unmount|status} <LABEL>"
	exit 1
	;;
esac
