#!/bin/bash

# Originally from:
# https://github.com/MacMiniVault/Mac-Scripts/blob/master/setupscript/setupscript.sh

# SET ENERGY PREFFERENCES
# SET AUTO POWER ON / WAKE EVERY MIDNIGHT
#sudo systemsetup -setallowpowerbuttontosleepcomputer off > /dev/null 2>&1
sudo pmset sleep 0
sudo pmset disksleep 0
sudo pmset displaysleep 0
sudo pmset autorestart 1
sudo pmset womp 1
sudo pmset repeat wakeorpoweron MTWRFSU  23:00:00
echo "ENERGY PREFERENCES ARE SET"
