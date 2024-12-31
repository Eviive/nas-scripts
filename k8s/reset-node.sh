#!/bin/bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'

id

if [ `id -u` -ne 0 ]; then
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

ip link delete cni0
ip link delete flannel.1

iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

echo -e "\nFinished resetting the node, the kubelet should be inactive...\n"
systemctl status kubelet

echo -e "\nYou can now re-join the cluster with 'kubeadm join'\n"

rm $0
