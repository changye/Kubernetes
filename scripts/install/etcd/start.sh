#!/usr/bin/env bash

HOST0=etcd0
HOST1=etcd1
HOST2=etcd2

HOST=$HOST0
HOSTIP=192.168.220.30
CLUSTER=etcd_cluster

etcd --name $HOST \
    --initial-cluster-token $CLUSTER \
    --initial-cluster-state new \
    --listen-client-urls http://$HOSTIP:2379,http://127.0.0.1:2379 \
    --listen-peer-urls http://$HOSTIP:2380 \
    --advertise-client-urls http://$HOST:2379 \
    --initial-advertise-peer-urls http://$HOST:2380 \
    --initial-cluster $HOST0=http://$HOST0:2380,$HOST1=http://$HOST1:2380,$HOST2=http://$HOST2:2380

