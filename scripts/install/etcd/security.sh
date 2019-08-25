#!/usr/bin/env bash


# Refrence https://coreos.com/os/docs/latest/generate-self-signed-certificates.html


# Install cfssl first.
mkdir -p ~/cfssl
cd ~/cfssl
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
sudo chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

# Initialize a certificate authority
cfssl print-defaults config > ca-config.json
cfssl print-defaults csr > ca-csr.json

# ca-config.json 

#{
#    "signing": {
#        "default": {
#            "expiry": "43800h"
#        },
#        "profiles": {
#            "server": {
#                "expiry": "43800h",
#                "usages": [
#                    "signing",
#                    "key encipherment",
#                    "server auth"
#                ]
#            },
#            "client": {
#                "expiry": "43800h",
#                "usages": [
#                    "signing",
#                    "key encipherment",
#                    "client auth"
#                ]
#            },
#            "peer": {
#                "expiry": "43800h",
#                "usages": [
#                    "signing",
#                    "key encipherment",
#                    "server auth",
#                    "client auth"
#                ]
#            }
#        }
#    }
#}


# ca-csr.json Certificate Signing Request (CSR)

#{
#    "CN": "My own CA",
#    "key": {
#        "algo": "rsa",
#        "size": 2048
#    },
#    "names": [
#        {
#            "C": "US",
#            "L": "CA",
#            "O": "My Company Name",
#            "ST": "San Francisco",
#            "OU": "Org Unit 1",
#            "OU": "Org Unit 2"
#        }
#    ]
#}


# Generate CA 
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

# Generate Server certificate

echo '{"CN":"etcd0","hosts":["192.168.220.30","127.0.0.1"],"key":{"algo":"rsa","size":4096}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server -hostname="192.168.220.30,127.0.0.1,etcd0" - | cfssljson -bare server-etcd0

echo '{"CN":"etcd1","hosts":["192.168.220.31","127.0.0.1"],"key":{"algo":"rsa","size":4096}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server -hostname="192.168.220.31,127.0.0.1,etcd1" - | cfssljson -bare server-etcd1

echo '{"CN":"etcd2","hosts":["192.168.220.32","127.0.0.1"],"key":{"algo":"rsa","size":4096}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server -hostname="192.168.220.32,127.0.0.1,etcd2" - | cfssljson -bare server-etcd2

# Generate peer certificate 

echo '{"CN":"etcd0","hosts":["192.168.220.30","127.0.0.1"],"key":{"algo":"rsa","size":4096}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.220.30,127.0.0.1,etcd0" - | cfssljson -bare etcd0 

echo '{"CN":"etcd1","hosts":["192.168.220.31","127.0.0.1"],"key":{"algo":"rsa","size":4096}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.220.31,127.0.0.1,etcd1" - | cfssljson -bare etcd1

echo '{"CN":"etcd2","hosts":["192.168.220.32","127.0.0.1"],"key":{"algo":"rsa","size":4096}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.220.32,127.0.0.1,etcd2" - | cfssljson -bare etcd2

# Generate Client certificate

echo '{"CN":"etcd0","hosts":["192.168.220.30","127.0.0.1"],"key":{"algo":"rsa","size":4096}}' | cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client - | cfssljson -bare client

# Copy certificates to all nodes

ssh -t etcd@etcd0 "sudo mkdir -pv /etc/ssl/etcd"
scp ca.pem server-etcd0.pem server-etcd0-key.pem etcd0.pem etcd0-key.pem etcd@etcd0:~/.
ssh -t etcd@etcd0 "sudo mv ~/ca.pem ~/server-etcd0.pem ~/server-etcd0-key.pem ~/etcd0.pem ~/etcd0-key.pem /etc/ssl/etcd/."

ssh -t etcd@etcd1 "sudo mkdir -pv /etc/ssl/etcd"
scp ca.pem server-etcd1.pem server-etcd1-key.pem etcd1.pem etcd1-key.pem etcd@etcd1:~/.
ssh -t etcd@etcd1 "sudo mv ~/ca.pem ~/server-etcd1.pem ~/server-etcd1-key.pem ~/etcd1.pem ~/etcd1-key.pem /etc/ssl/etcd/."

ssh -t etcd@etcd2 "sudo mkdir -pv /etc/ssl/etcd"
scp ca.pem server-etcd2.pem server-etcd2-key.pem etcd2.pem etcd2-key.pem etcd@etcd2:~/.
ssh -t etcd@etcd2 "sudo mv ~/ca.pem ~/server-etcd2.pem ~/server-etcd2-key.pem ~/etcd2.pem ~/etcd2-key.pem /etc/ssl/etcd/."
