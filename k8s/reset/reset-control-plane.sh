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

rm -rf /etc/kubernetes
rm -rf /var/lib/etcd
rm -rf /var/lib/kubelet/*
rm -rf /var/lib/dockershim
rm -rf /etc/cni/net.d
rm -rf /opt/cni/bin

ip link delete cni0
ip link delete flannel.1

iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

echo -e "\nFinished resetting the control plane, you can now re-initialize the cluster with 'kubeadm init' and 'kubeadm join'"
echo "kubeadm init --control-plane-endpoint=<endpoint> --node-name <node-name> --pod-network-cidr=10.244.0.0/16"

rm $0
