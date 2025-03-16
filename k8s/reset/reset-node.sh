#!/bin/bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'

id

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root"
	exit 1
fi

systemctl stop kubelet
systemctl stop containerd

kubeadm reset -f

rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/net.d
rm -rf /opt/cni/bin
rm -rf /etc/kubernetes

ip link delete flannel.1

iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

echo -e "\nFinished resetting the node, you can now re-join the cluster with 'kubeadm join'"
echo "You can generate a join token with 'kubeadm token create --print-join-command'"

rm "$0"
