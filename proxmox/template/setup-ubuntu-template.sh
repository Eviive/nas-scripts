#!/bin/bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'

if [[ $(id -u) -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

cd ~ || exit

first_boot_script="first-boot.sh"
this_user=$SUDO_USER
wget https://raw.githubusercontent.com/Eviive/nas-scripts/main/proxmox/template/$first_boot_script
chmod +x $first_boot_script
chown "$this_user":"$this_user" $first_boot_script

(crontab -l 2>/dev/null; echo "@reboot HOME=$HOME $(realpath $first_boot_script)") | crontab -

apt update
apt -y full-upgrade
apt install -y qemu-guest-agent

truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

logrotate -f /etc/logrotate.conf

systemctl stop syslog.socket rsyslog.service

service rsyslog stop

if [[ -f /var/log/audit/audit.log ]]; then
    cat /dev/null > /var/log/audit/audit.log
fi
if [[ -f /var/log/wtmp ]]; then
    cat /dev/null > /var/log/wtmp
fi
if [[ -f /var/log/lastlog ]]; then
    cat /dev/null > /var/log/lastlog
fi

if [[ -f /etc/udev/rules.d/70-persistent-net.rules ]]; then
    rm /etc/udev/rules.d/70-persistent-net.rules
fi

rm -rf /tmp/*
rm -rf /var/tmp/*

apt clean
apt autoremove

rm "$0"

echo -e "\nFinished setup, clean the history and power off the machine\n"
