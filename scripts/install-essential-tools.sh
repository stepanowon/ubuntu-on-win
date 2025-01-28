#!/usr/bin/env bash

set -euo pipefail

sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's/security.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list.d/ubuntu.sources

apt update 
#apt upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

apt install virtualbox-guest-additions-iso -y

echo virtualbox-ext-pack virtualbox-ext-pack/license select true | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get install -y virtualbox-ext-pack

apt install -y curl wget jq net-tools
apt install -y git-all maven
apt install -y openjdk-17-jdk-headless

timedatectl set-timezone 'Asia/Seoul'
timedatectl set-ntp true
