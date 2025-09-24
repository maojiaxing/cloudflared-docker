#!/usr/bin/env sh

if ! id "$USER" >/dev/null 2>&1; then
    echo "Creating user: $USER"
    adduser -D "$USER"
    echo "$USER:$PASSWORD" | chpasswd
    # 添加sudo权限
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo 'Port $PORT' > /etc/ssh/sshd_config
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
    chmod 600 /etc/ssh/sshd_config
    chown root:root /etc/ssh/sshd_config
fi

cp /tmp/bashrc "/home/$USER/.bashrc"
cp /tmp/profile "/home/$USER/.profile"

CONFIG_DIR="/home/$USER/.config"
SUPERVISORD_CONF_DIR="$CONFIG_DIR/supervisor"
CREDENTIALS_DIR="/home/$USER/.config/cloudflared"
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

cp /tmp/supervisord.conf "$SUPERVISORD_CONF_DIR/"
envsubst '$USER $PORT' < /tmp/sshd.service > "$SUPERVISORD_CONF_DIR/conf.d/sshd.service"
envsubst '$USER' < /tmp/cloudflared.service > "$SUPERVISORD_CONF_DIR/conf.d/cloudflared.service"
chmod 755 /var/log/supervisor

exec supervisord -c "/home/$USER/.config/supervisor/supervisord.conf"
