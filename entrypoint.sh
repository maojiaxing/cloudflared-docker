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

CONFIG_DIR="/home/$USER/.config"
SUPERVISORD_CONF_DIR="$CONFIG_DIR/supervisor"

if [ ! -d "$CONFIG_DIR" ]; then
  mkdir -p "$CONFIG_DIR"
  mkdir -p "$SUPERVISORD_CONF_DIR"
  mkdir -p "$SUPERVISORD_CONF_DIR/conf.d"
fi

cp /tmp/supervisord.conf "$SUPERVISORD_CONF_DIR/"
envsubst '$USER' < /tmp/sshd.service > "$SUPERVISORD_CONF_DIR/conf.d/sshd.service"
envsubst '$USER' < /tmp/cloudflare.service > "$SUPERVISORD_CONF_DIR/conf.d/cloudflare.service"

exec supervisord -c /home/nonroot/.config/supervisor/supervisord.conf
