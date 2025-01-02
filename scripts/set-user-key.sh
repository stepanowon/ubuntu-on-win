#!/usr/bin/env bash

set -euo pipefail

USERNAME="user1"
PASSWORD="asdf"
SSHDIR="/home/$USERNAME/.ssh"


useradd -m -s /bin/bash -p $PASSWORD $USERNAME
usermod -a -G sudo $USERNAME

# user1 사용자 추가 & 패스워드 설정
echo "$USERNAME:$PASSWORD" | chpasswd $USERNAME
# SSH 키 생성
if [ ! -f $SSHDIR/id_rsa ]; then
  sudo -u $USERNAME ssh-keygen -t rsa -b 2048 -f $SSHDIR/id_rsa -q -N ""
  echo "SSH key generated for $USERNAME at $SSHDIR/id_rsa"
else
  echo "SSH key already exists for #{target_user}"
fi

# 적절한 권한 설정
chmod 600 $SSHDIR/id_rsa
chmod 644 $SSHDIR/id_rsa.pub

cat $SSHDIR/id_rsa.pub > $SSHDIR/authorized_keys
chmod 644 $SSHDIR/authorized_keys    
chown user1 $SSHDIR/authorized_keys
chgrp user1 $SSHDIR/authorized_keys