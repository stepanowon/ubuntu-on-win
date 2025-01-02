#!/usr/bin/env bash

set -euo pipefail

sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's/security.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list.d/ubuntu.sources

apt update -y
apt upgrade -y

apt install virtualbox-guest-additions-iso -y

apt install -y curl wget jq net-tools
apt install -y git-all maven
apt install -y openjdk-17-jdk-headless

timedatectl set-timezone 'Asia/Seoul'
timedatectl set-ntp true
