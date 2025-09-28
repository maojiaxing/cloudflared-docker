#!/bin/bash

# --- 1. 变量和错误检查 ---
if [ -z "$USER" ] || [ -z "$PASSWORD" ] || [ -z "$TUNNEL_TOKEN" ]; then
    echo "ERROR: 必须设置 USER, PASSWORD 和 TUNNEL_TOKEN 环境变量" >&2
    exit 1
fi

# 定义所有路径
USER_HOME="/home/$USER"
CONFIG_DIR="$USER_HOME/.config"
SUPERVISORD_CONF_DIR="$CONFIG_DIR/supervisor"
# CREDENTIALS_DIR="$CONFIG_DIR/cloudflared"
# CREDENTIALS_FILE="$CREDENTIALS_DIR/credentials.json"

STATE_DIR="$USER_HOME/.local/state"
SUPERVISOR_STATE_DIR="$STATE_DIR/supervisor"

if ! id "$USER" >/dev/null 2>&1; then
    echo "Creating user: $USER"
    # -m 会创建主目录
    useradd -m -s /bin/bash -G sudo "$USER"
    echo "$USER:$PASSWORD" | chpasswd
    
    # 添加 sudo NOPASSWD 权限
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# 确保 home 目录本身的权限是 755
chmod 755 "$USER_HOME"

cp /tmp/bashrc "$USER_HOME/.bashrc"
cp /tmp/profile "$USER_HOME/.profile"

mkdir -p "$SUPERVISORD_CONF_DIR/conf.d"
# mkdir -p "$CREDENTIALS_DIR"
mkdir -p "$SUPERVISOR_STATE_DIR"

chown -R "$USER:$USER" "$USER_HOME"

# chmod 700 "$CREDENTIALS_DIR"

# echo "{\"TunnelToken\":\"$TUNNEL_TOKEN\"}" > "$CREDENTIALS_FILE"
# chmod 600 "$CREDENTIALS_FILE" # 只有所有者可读写

envsubst '$USER' < /tmp/supervisord.conf > "$SUPERVISORD_CONF_DIR/supervisord.conf"
envsubst '$USER $PORT' < /tmp/sshd.service > "$SUPERVISORD_CONF_DIR/conf.d/sshd.service"
envsubst '$USER $TUNNEL_TOKEN' < /tmp/cloudflared.service > "$SUPERVISORD_CONF_DIR/conf.d/cloudflared.service"

chmod 644 "$SUPERVISORD_CONF_DIR/supervisord.conf"
chmod 644 "$SUPERVISORD_CONF_DIR/conf.d/sshd.service"
chmod 644 "$SUPERVISORD_CONF_DIR/conf.d/cloudflared.service"

echo "Port $PORT" > /etc/ssh/sshd_config
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config

mkdir -p /var/log/supervisor
chown "$USER:$USER" /var/log/supervisor

echo "Starting supervisord as user: $USER"
exec sudo -u "$USER" supervisord -c "$SUPERVISORD_CONF_DIR/supervisord.conf"
