#!/usr/bin/env bash

set -euo pipefail

cat << EOF > /etc/hosts
127.0.0.1			localhost

192.168.56.101  	server1
192.168.56.102  	server2
192.168.56.103  	server3
EOF

cat /etc/hosts
