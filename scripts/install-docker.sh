#!/usr/bin/env bash

set -euo pipefail

apt update -y
apt-get install apt-transport-https ca-certificates curl -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -


add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) \
stable"

apt update -y

apt-get install docker-ce docker-ce-cli containerd.io -y

docker version
docker info

usermod -a -G docker user1

systemctl enable docker
systemctl start docker
chmod 666 /var/run/docker.sock

