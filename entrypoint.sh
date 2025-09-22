#!/usr/bin/env sh

if ! id "$USER" >/dev/null 2>&1; then
    echo "Creating user: $USER"
    adduser -D "$USER"
    echo "$USER:$PASSWORD" | chpasswd
    # 添加sudo权限
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo 'PermitRootLogin no' > /etc/ssh/sshd_config.d/_sshd.conf
fi

envsubst '${PORT}' < /etc/ssh/config.template > /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config

tunnel --no-autoupdate run --token $TOKEN
