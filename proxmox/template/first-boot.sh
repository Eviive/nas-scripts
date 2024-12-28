#!/bin/sh

set -euo pipefail

this_file=${0##*/}

id

if [ `id -u` -ne 0 ]; then
	echo "This script must be run as root"
	exit 1
fi

apt update
apt -y full-upgrade

crontab -l | grep -v $(realpath $this_file) | crontab -

rm $this_file

echo "\nFinished first boot, rebooting...\n"
reboot
