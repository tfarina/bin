#!/bin/bash

action="$1"
label="$2"

if [[ -z "$action" || -z "$label" ]]; then
    echo "Usage: $0 {mount|unmount|status} <LABEL>"
    exit 1
fi

# Find device by label
device=$(lsblk -nrpo NAME,LABEL | awk -v label="$label" '$2 == label {print $1; exit}')

if [[ -z "$device" ]]; then
    echo "Device with label '$label' not found."
    exit 1
fi

mountPoint="/media/$USER/$label"

fsType=$(lsblk -no FSTYPE "$device")

case "$fsType" in
    vfat|fat|msdos)
        mountOptions="rw,uid=$(id -u),gid=$(id -g),fmask=0022,dmask=0022,utf8=1,shortname=mixed"
        ;;
    ext4)
        mountOptions="rw"
        ;;
    *)
        echo "Unsupported or unrecognized filesystem: '$fsType'"
        exit 1
        ;;
esac

case "$action" in
    mount)
	echo "Mounting $device to $mountPoint..."
	sudo mkdir -p "$mountPoint"
	sudo mount -o "$mountOptions" "$device" "$mountPoint"
	;;
    unmount|umount)
	echo "Unmounting $device from $mountPoint..."
	sudo umount "$mountPoint"
	;;
    status)
	currentMountPoint=$(findmnt --source "LABEL=$label" --noheadings --output TARGET)
	if [[ -n "$currentMountPoint" ]]; then
	    echo "$label is mounted at $currentMountPoint"
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
