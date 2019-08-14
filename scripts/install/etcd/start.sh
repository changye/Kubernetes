#!/usr/bin/env bash

HOST0=etcd0
HOST1=etcd1
HOST2=etcd2

HOST0IP="192.168.220.30"
HOST1IP="192.168.220.31"
HOST2IP="192.168.220.32"


# Add hosts to /etc/hosts
echo $HOST0IP  $HOST0 >> /etc/hosts
echo $HOST1IP  $HOST1 >> /etc/hosts
echo $HOST2IP  $HOST2 >> /etc/hosts


HOST=$HOST0
HOSTIP=$HOST0IP
CLUSTER=etcd_cluster

#etcd --name $HOST \
#    --initial-cluster-token $CLUSTER \
#    --initial-cluster-state new \
#    --listen-client-urls http://$HOSTIP:2379,http://127.0.0.1:2379 \
#    --listen-peer-urls http://$HOSTIP:2380 \
#    --advertise-client-urls http://$HOST:2379 \
#    --initial-advertise-peer-urls http://$HOST:2380 \
#    --initial-cluster $HOST0=http://$HOST0:2380,$HOST1=http://$HOST1:2380,$HOST2=http://$HOST2:2380


sudo mkdir -p /etc/etcd
sudo tee /etc/etcd/etcd.conf <<EOF
ETCD_NAME=$HOST
ETCD_DATA_DIR="/var/lib/etcd/etcd"
ETCD_LISTEN_PEER_URLS="http://$HOSTIP:2380"
ETCD_LISTEN_CLIENT_URLS="http://$HOSTIP:2379,http://127.0.0.1:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$HOST:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://$HOST:2379"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="$CLUSTER"
ETCD_INITIAL_CLUSTER="$HOST0=http://$HOST0:2380,$HOST1=http://$HOST1:2380,$HOST2=http://$HOST2:2380"
EOF

sudo mkdir -p /var/lib/etcd/etcd
sudo mkdir -p /usr/lib/systemd/system
sudo tee  /usr/lib/systemd/system/etcd.service <<'EOF'
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
EnvironmentFile=-/etc/etcd/etcd.conf
# User=etcd
# set GOMAXPROCS to number of processors
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/local/bin/etcd --name=\"${ETCD_NAME}\" --data-dir=\"${ETCD_DATA_DIR}\" --listen-client-urls=\"${ETCD_LISTEN_CLIENT_URLS}\" --listen-peer-urls=\"${ETCD_LISTEN_PEER_URLS}\" --advertise-client-urls=\"${ETCD_ADVERTISE_CLIENT_URLS}\" --initial-cluster-token=\"${ETCD_INITIAL_CLUSTER_TOKEN}\" --initial-cluster=\"${ETCD_INITIAL_CLUSTER}\" --initial-cluster-state=\"${ETCD_INITIAL_CLUSTER_STATE}\" "
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
