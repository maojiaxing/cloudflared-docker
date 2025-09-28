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
CREDENTIALS_DIR="$CONFIG_DIR/cloudflared"
CREDENTIALS_FILE="$CREDENTIALS_DIR/credentials.json"

# --- 2. 用户创建和配置 (以 root 身份执行) ---
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

# --- 3. 文件和目录操作 (以 root 身份操作，并更改所有权) ---

# A. 复制用户配置文件
cp /tmp/bashrc "$USER_HOME/.bashrc"
cp /tmp/profile "$USER_HOME/.profile"

# B. 创建配置目录
mkdir -p "$SUPERVISORD_CONF_DIR/conf.d"
mkdir -p "$CREDENTIALS_DIR"

# C. 核心：将所有用户文件和目录的所有权递归地转移给新用户
chown -R "$USER:$USER" "$USER_HOME"

# D. 设置敏感目录权限
chmod 700 "$CREDENTIALS_DIR"

# E. 生成凭证文件
echo "{\"TunnelToken\":\"$TUNNEL_TOKEN\"}" > "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE" # 只有所有者可读写

# F. 环境变量替换并生成 Supervisor 配置
envsubst '$USER' < /tmp/supervisord.conf > "$SUPERVISORD_CONF_DIR/supervisord.conf"
envsubst '$USER $PORT' < /tmp/sshd.service > "$SUPERVISORD_CONF_DIR/conf.d/sshd.service"
envsubst '$USER' < /tmp/cloudflared.service > "$SUPERVISORD_CONF_DIR/conf.d/cloudflared.service"

# G. 确保 Supervisor 配置文件的权限（已在 chown -R 中处理所有权，这里设置具体权限）
chmod 644 "$SUPERVISORD_CONF_DIR/supervisord.conf"
chmod 644 "$SUPERVISORD_CONF_DIR/conf.d/sshd.service"
chmod 644 "$SUPERVISORD_CONF_DIR/conf.d/cloudflared.service"

# H. 配置 sshd 系统文件（必须是 root 拥有）
echo "Port $PORT" > /etc/ssh/sshd_config
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
# chown/chmod 确保安全，虽然大多数基础镜像中已设置
chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config

# I. 确保 Supervisor 日志目录可写
mkdir -p /var/log/supervisor
chown "$USER:$USER" /var/log/supervisor
# 如果日志目录需要被新用户写入，必须将所有权转给新用户

# --- 4. 启动服务 ---
echo "Starting supervisord as user: $USER"
# exec 切换到新用户并启动 supervisord
exec sudo -u "$USER" supervisord -c "$SUPERVISORD_CONF_DIR/supervisord.conf"
