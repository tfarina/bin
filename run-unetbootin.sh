#!/bin/bash

# Wrapper script to launch UNetbootin with the QT_X11_NO_MITSHM workaround.
#
# Why this is needed:
# UNetbootin is a Qt application, and it may fail to display properly
# (e.g., showing a blank or garbled window, or crashing) when run under
# X11 environments where the MIT-SHM (shared memory) extension is not
# available or not compatible (such as remote X11, XWayland, or certain
# compositors).
#
# Setting QT_X11_NO_MITSHM=1 disables the use of shared memory in Qt,
# which fixes these rendering issues. Root privileges are required
# for writing to USB drives, so we use `sudo env` to ensure the variable
# is passed correctly.

UNETBOOTIN_BIN="./unetbootin-linux-702.bin"

if [[ ! -x "$UNETBOOTIN_BIN" ]]; then
    echo "Error: '$UNETBOOTIN_BIN' not found or not executable."
    exit 1
fi

# Run with workaround
sudo env QT_X11_NO_MITSHM=1 "$UNETBOOTIN_BIN"
