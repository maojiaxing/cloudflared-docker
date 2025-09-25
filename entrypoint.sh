#!/bin/bash

if [ -z "$USER" ] || [ -z "$PASSWORD" ]; then
    echo "ERROR: 必须设置 USER 和 PASSWORD 环境变量"
    exit 1
fi

echo "Creating user: $USER"
useradd -m -s /bin/bash -G sudo "$USER"
echo "$USER:$PASSWORD" | chpasswd

if ! id "$USER" >/dev/null 2>&1; then
    echo "Creating user: $USER"
    useradd -m -s /bin/bash $USER
    echo "$USER:$PASSWORD" | chpasswd
    usermod -aG sudo $USER
    # 添加sudo权限
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo 'Port $PORT' > /etc/ssh/sshd_config
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
    chmod 600 /etc/ssh/sshd_config
    chown root:root /etc/ssh/sshd_config
    chmod 755 "$USER_HOME"
fi

cp /tmp/bashrc "/home/$USER/.bashrc"
cp /tmp/profile "/home/$USER/.profile"

USER_HOME="/home/$USER"
CONFIG_DIR="$USER_HOME/.config"
SUPERVISORD_CONF_DIR="$CONFIG_DIR/supervisor"
CREDENTIALS_DIR="$CONFIG_DIR/cloudflared"
CREDENTIALS_FILE="$CREDENTIALS_DIR/credentials.json"

if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$SUPERVISORD_CONF_DIR"
    mkdir -p "$SUPERVISORD_CONF_DIR/conf.d"
fi

if [ -z "$TUNNEL_TOKEN" ]; then
    echo "错误：未提供TUNNEL_TOKEN环境变量"
    exit 1
fi

if [ ! -d "$CREDENTIALS_DIR" ]; then
    mkdir -p "$CREDENTIALS_DIR"
    chown "$USER:$USER" "$CREDENTIALS_DIR"
    chmod 700 "$CREDENTIALS_DIR"
fi

# 生成凭证文件
echo "{\"TunnelToken\":\"$TUNNEL_TOKEN\"}" > "$CREDENTIALS_FILE"
chown "$USER:$USER" "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE"
chmod 644 "$USER_HOME/.config/supervisor/conf.d/*"

envsubst '$USER' < /tmp/supervisord.conf > "$SUPERVISORD_CONF_DIR/supervisord.conf"
envsubst '$USER $PORT' < /tmp/sshd.service > "$SUPERVISORD_CONF_DIR/conf.d/sshd.service"
envsubst '$USER' < /tmp/cloudflared.service > "$SUPERVISORD_CONF_DIR/conf.d/cloudflared.service"
chmod 755 /var/log/supervisor

exec sudo -u "$USER" supervisord -c "$SUPERVISORD_CONF_DIR/supervisord.conf"
