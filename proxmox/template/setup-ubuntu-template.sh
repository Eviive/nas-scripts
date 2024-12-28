#!/bin/bash

set -euo pipefail

this_file=${0##*/}

id

if [ `id -u` -ne 0 ]; then
	echo "This script must be run as root"
	exit 1
fi

cd ~

first_boot_script=first-boot.sh
this_user=$SUDO_USER
wget https://github.com/Eviive/nas-utils/raw/main/proxmox/template/$first_boot_script
chmod +x $first_boot_script
chown $this_user:$this_user $first_boot_script

(crontab -l 2>/dev/null; echo "@reboot $TARGET_SCRIPT") | crontab -

apt update
apt -y full-upgrade
apt install -y qemu-guest-agent

sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /var/lib/dbus/machine-id /etc/machine-id

logrotate -f /etc/logrotate.conf

service rsyslog stop

if [ -f /var/log/audit/audit.log ]; then
    cat /dev/null > /var/log/audit/audit.log
fi
if [ -f /var/log/wtmp ]; then
    cat /dev/null > /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    cat /dev/null > /var/log/lastlog
fi

if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
    rm /etc/udev/rules.d/70-persistent-net.rules
fi

rm -rf /tmp/*
rm -rf /var/tmp/*

apt clean
apt autoremove

history -c
history -w

rm $this_file
