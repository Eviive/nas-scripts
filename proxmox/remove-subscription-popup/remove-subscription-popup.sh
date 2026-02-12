#!/bin/bash

cp /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak

sed -i.bak "s/.data.status.toLowerCase() !== 'active'/.data.status.toLowerCase() === 'active'/" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

if [[ $(systemctl is-active pveproxy.service) = 'active' ]] then
    systemctl restart pveproxy.service
fi

if [[ $(systemctl is-active proxmox-backup-proxy.service) = 'active' ]] then
    systemctl restart proxmox-backup-proxy.service
fi
