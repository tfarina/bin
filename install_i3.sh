#!/bin/csh

setenv PATH "/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:/root/bin"

pkg update -f

pkg install -y xorg-server xinit xscreensaver xf86-input-keyboard xf86-input-mouse

pkg install -y i3 i3lock i3status

echo "/usr/local/bin/i3" >> /usr/home/tfarina/.xinitrc
chown tfarina /usr/home/tfarina/.xinitrc

pkg install -y xorg-drivers

echo 'sem_load="YES"' >> /boot/loader.conf
echo 'linux_load="YES"' >> /boot/loader.conf

cat << EOF >> /etc/rc.conf
hald_enable="YES"
dbus_enable="YES"
EOF

cat << EOF >> /etc/sysctl.conf
kern.ipc.shm_allow_removed=1
hw.syscons.kbd_reboot=0
EOF
