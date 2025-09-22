#!/usr/bin/env sh

if ! id "$USER" >/dev/null 2>&1; then
    echo "Creating user: $USER"
    adduser -D "$USER"
    echo "$USER:$PASSWORD" | chpasswd
    # 添加sudo权限
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo 'PermitRootLogin no' > /etc/ssh/sshd_config.d/_sshd.conf
fi

