# Reset K8s Cluster

## Reset the control plane

```bash
wget https://raw.githubusercontent.com/Eviive/nas-scripts/main/k8s/reset-control-plane.sh
chmod +x reset-control-plane.sh
sudo ./reset-control-plane.sh
```

## Reset the node

```bash
wget https://raw.githubusercontent.com/Eviive/nas-scripts/main/k8s/reset-node.sh
chmod +x reset-node.sh
sudo ./reset-node.sh
```
